<?php

namespace Tests\Feature;

use Tests\TestCase;
use App\Models\User;
use App\Models\Order;
use App\Models\Menu;
use App\Models\OrderAdditionRequest;
use App\Models\OrderAdditionItem;
use Database\Seeders\DatabaseSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;

class OrderAdditionTest extends TestCase
{
    use RefreshDatabase;

    protected $admin;
    protected $customer;
    protected $order;
    protected $menu;

    protected function setUp(): void
    {
        parent::setUp();
        
        $this->seed(DatabaseSeeder::class);

        $this->admin = User::where('role_id', 1)->first();
        $this->customer = User::where('role_id', 2)->first();
        $this->menu = Menu::first();

        $this->order = Order::create([
            'user_id' => $this->customer->user_id,
            'event_address' => 'Jl. Pardede No. 1',
            'event_latitude' => 2.437190,
            'event_longitude' => 99.157618,
            'status_id' => 1, // Pending
            'final_price' => 100000.00,
            'order_date' => now(),
            'event_date' => now()->addDays(7),
            'people' => 10,
            'total_paid' => 0.00
        ]);
    }

    /** @test */
    public function pelanggan_bisa_mengajukan_tambahan_menu_via_api()
    {
        $response = $this->actingAs($this->customer, 'sanctum')
            ->postJson("/api/orders/{$this->order->order_id}/additions", [
                'menu_ids' => [$this->menu->menu_id],
                'notes' => 'Tolong buat agak pedas'
            ]);

        $response->assertStatus(201);

        $this->assertDatabaseHas('order_addition_requests', [
            'order_id' => $this->order->order_id,
            'status_id' => 1, // Pending
            'notes' => 'Tolong buat agak pedas'
        ]);

        $request = OrderAdditionRequest::where('order_id', $this->order->order_id)->first();
        $this->assertDatabaseHas('order_addition_items', [
            'request_id' => $request->id,
            'menu_id' => $this->menu->menu_id
        ]);
    }

    /** @test */
    public function admin_bisa_menyetujui_permintaan_tambahan_pesanan()
    {
        // 1. Buat permintaan tambahan awal berstatus Pending
        $additionRequest = OrderAdditionRequest::create([
            'order_id' => $this->order->order_id,
            'status_id' => 1, // Pending
            'notes' => 'Permintaan tambahan tes'
        ]);

        $additionItem = OrderAdditionItem::create([
            'request_id' => $additionRequest->id,
            'menu_id' => $this->menu->menu_id,
            'final_price' => 0.00
        ]);

        // Mock Firebase Push Notification untuk menghindari pemanggilan real FCM API
        $mock = \Mockery::mock('alias:\App\Services\FirebaseService'); // not used directly in method but inside sendPush
        // Kita cukup abaikan pemanggilan push dengan menguji redirect dan status perubahan
        
        // 2. Admin menyetujui dan mengisi harga final menu tambahan
        $response = $this->actingAs($this->admin)
            ->post(route('additions.approve', $additionRequest->id), [
                'prices' => [
                    $additionItem->id => 25000.00
                ]
            ]);

        $response->assertRedirect();

        $additionRequest->refresh();
        $this->assertEquals(2, $additionRequest->status_id); // 2 = Approved

        $additionItem->refresh();
        $this->assertEquals(25000.00, (float)$additionItem->final_price);

        // Pastikan final price pesanan utama ikut naik (karena getRemainingBalance / getTotalPayable mengambil additions status 2)
        $this->order->refresh();
        $this->assertEquals(125000.00, (float)$this->order->total_payable);
    }

    /** @test */
    public function admin_bisa_menolak_permintaan_tambahan_pesanan()
    {
        // 1. Buat permintaan tambahan
        $additionRequest = OrderAdditionRequest::create([
            'order_id' => $this->order->order_id,
            'status_id' => 1, // Pending
            'notes' => 'Permintaan tambahan ditolak'
        ]);

        $additionItem = OrderAdditionItem::create([
            'request_id' => $additionRequest->id,
            'menu_id' => $this->menu->menu_id,
            'final_price' => 0.00
        ]);

        // 2. Admin menolak pengajuan tambahan
        $response = $this->actingAs($this->admin)
            ->post(route('additions.reject', $additionRequest->id));

        $response->assertRedirect();

        $additionRequest->refresh();
        $this->assertEquals(3, $additionRequest->status_id); // 3 = Rejected

        // Pastikan harga pesanan katering utama tidak berubah
        $this->order->refresh();
        $this->assertEquals(100000.00, (float)$this->order->total_payable);
    }
}
