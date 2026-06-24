<?php

namespace Tests\Feature;

use Tests\TestCase;
use App\Models\User;
use App\Models\Order;
use App\Models\OrderStatus;
use Database\Seeders\DatabaseSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;

class OrderAdminManagementTest extends TestCase
{
    use RefreshDatabase;

    protected $admin;
    protected $driver;
    protected $customer;
    protected $order;

    protected function setUp(): void
    {
        parent::setUp();
        
        $this->seed(DatabaseSeeder::class);

        $this->admin = User::where('role_id', 1)->first();
        $this->driver = User::where('role_id', 3)->first(); // Sopir
        $this->customer = User::where('role_id', 2)->first();
        
        // Buat pesanan baru berstatus Pending (1)
        $this->order = Order::create([
            'user_id' => $this->customer->user_id,
            'event_address' => 'Jl. Pardede No. 1',
            'event_latitude' => 2.437190,
            'event_longitude' => 99.157618,
            'status_id' => 1, // Pending
            'final_price' => 150000.00,
            'order_date' => now(),
            'event_date' => now()->addDays(7),
            'people' => 10,
            'total_paid' => 0.00
        ]);

        // Buat order item
        $this->order->items()->create([
            'menu_id' => 1,
            'final_price' => 150000.00
        ]);
    }

    /** @test */
    public function admin_bisa_memperbarui_proposal_harga_item_pesanan()
    {
        $this->order->load('items');
        $item = $this->order->items->first();

        // Admin mengubah harga item pesanan
        $response = $this->actingAs($this->admin)
            ->post(route('orders.updateItemPrices', $this->order->order_id), [
                'prices' => [
                    $item->order_item_id => 120000.00
                ]
            ]);

        $response->assertRedirect();
        $response->assertSessionHas('success');

        $this->order->refresh();
        $this->assertEquals(120000.00, (float)$this->order->final_price);

        // Pastikan harga item terupdate
        $item->refresh();
        $this->assertEquals(120000.00, (float)$item->final_price);
    }

    /** @test */
    public function admin_bisa_menugaskan_sopir_aktif_ke_pesanan()
    {
        $response = $this->actingAs($this->admin)
            ->post(route('orders.assignDriver', $this->order->order_id), [
                'driver_id' => $this->driver->user_id
            ]);

        $response->assertRedirect();
        $response->assertSessionHas('success');

        $this->order->refresh();
        $this->assertEquals($this->driver->user_id, $this->order->driver_id);
    }

    /** @test */
    public function admin_bisa_memperbarui_status_logistik_pesanan()
    {
        // Set total_paid ke 50% DP terlebih dahulu agar bisa diproses
        $this->order->total_paid = 75000.00;
        $this->order->is_price_confirmed = true;
        $this->order->save();

        // Hubungkan ke status mempersiapkan (2)
        $response = $this->actingAs($this->admin)
            ->patch(route('orders.updateStatus', $this->order->order_id), [
                'status_id' => 2
            ]);

        $response->assertRedirect();
        $response->assertSessionHas('success');

        $this->order->refresh();
        $this->assertEquals(2, $this->order->status_id);
    }

    /** @test */
    public function admin_tidak_bisa_memperbarui_status_pesanan_ke_diproses_jika_belum_membayar_dp()
    {
        $this->order->is_price_confirmed = true;
        $this->order->save();

        // Hubungkan ke status mempersiapkan (2) dengan total_paid = 0
        $response = $this->actingAs($this->admin)
            ->patch(route('orders.updateStatus', $this->order->order_id), [
                'status_id' => 2
            ]);

        $response->assertRedirect();
        $response->assertSessionHas('error', 'Pesanan tidak dapat diproses karena pembayaran belum mencapai minimal DP 50% atau Lunas. (Telah dibayar: Rp 0 dari minimal: Rp 75.000)');

        $this->order->refresh();
        $this->assertEquals(1, $this->order->status_id); // Tetap Pending
    }

    /** @test */
    public function admin_bisa_memperbarui_status_pesanan_ke_diproses_jika_sudah_membayar_dp_50_persen()
    {
        // Set total_paid tepat 50% DP (75.000)
        $this->order->total_paid = 75000.00;
        $this->order->is_price_confirmed = true;
        $this->order->save();

        $response = $this->actingAs($this->admin)
            ->patch(route('orders.updateStatus', $this->order->order_id), [
                'status_id' => 2
            ]);

        $response->assertRedirect();
        $response->assertSessionHas('success');

        $this->order->refresh();
        $this->assertEquals(2, $this->order->status_id);
    }

    /** @test */
    public function admin_bisa_memperbarui_status_pesanan_ke_diproses_jika_sudah_lunas()
    {
        // Set total_paid lunas 100% (150.000)
        $this->order->total_paid = 150000.00;
        $this->order->is_price_confirmed = true;
        $this->order->save();

        $response = $this->actingAs($this->admin)
            ->patch(route('orders.updateStatus', $this->order->order_id), [
                'status_id' => 2
            ]);

        $response->assertRedirect();
        $response->assertSessionHas('success');

        $this->order->refresh();
        $this->assertEquals(2, $this->order->status_id);
    }

    /** @test */
    public function admin_bisa_mengonfirmasi_harga_pesanan()
    {
        $this->order->load('items');
        $item = $this->order->items->first();

        $response = $this->actingAs($this->admin)
            ->post(route('orders.confirmPrice', $this->order->order_id), [
                'prices' => [
                    $item->order_item_id => 130000.00
                ]
            ]);

        $response->assertRedirect();
        $response->assertSessionHas('success');

        $this->order->refresh();
        $this->assertTrue((bool)$this->order->is_price_confirmed);
        $this->assertEquals(130000.00, (float)$this->order->final_price);

        // Pastikan terekam di log aktivitas
        $this->assertDatabaseHas('order_activities', [
            'order_id' => $this->order->order_id,
            'type' => 'price_confirmed'
        ]);
    }

    /** @test */
    public function admin_tidak_bisa_memperbarui_harga_setelah_dikonfirmasi()
    {
        $this->order->is_price_confirmed = true;
        $this->order->save();

        $this->order->load('items');
        $item = $this->order->items->first();

        // Coba perbarui harga draft
        $response = $this->actingAs($this->admin)
            ->post(route('orders.updateItemPrices', $this->order->order_id), [
                'prices' => [
                    $item->order_item_id => 140000.00
                ]
            ]);

        $response->assertRedirect();
        $response->assertSessionHas('error');

        // Coba konfirmasi harga lagi
        $response2 = $this->actingAs($this->admin)
            ->post(route('orders.confirmPrice', $this->order->order_id), [
                'prices' => [
                    $item->order_item_id => 140000.00
                ]
            ]);

        $response2->assertRedirect();
        $response2->assertSessionHas('error');
    }

    /** @test */
    public function admin_tidak_bisa_memperbarui_status_pesanan_jika_harga_belum_dikonfirmasi()
    {
        // total_paid >= 50% DP (75.000) tapi is_price_confirmed = false
        $this->order->total_paid = 75000.00;
        $this->order->is_price_confirmed = false;
        $this->order->save();

        $response = $this->actingAs($this->admin)
            ->patch(route('orders.updateStatus', $this->order->order_id), [
                'status_id' => 2
            ]);

        $response->assertRedirect();
        $response->assertSessionHas('error', 'Pesanan tidak dapat diproses karena harga belum dikonfirmasi oleh Admin.');

        $this->order->refresh();
        $this->assertEquals(1, $this->order->status_id); // Tetap Pending
    }
}
