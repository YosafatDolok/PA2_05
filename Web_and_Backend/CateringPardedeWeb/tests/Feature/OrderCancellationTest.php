<?php

namespace Tests\Feature;

use Tests\TestCase;
use App\Models\User;
use App\Models\Order;
use Database\Seeders\DatabaseSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Bus;

class OrderCancellationTest extends TestCase
{
    use RefreshDatabase;

    protected $admin;
    protected $customer;
    protected $order;

    protected function setUp(): void
    {
        parent::setUp();

        $this->seed(DatabaseSeeder::class);

        $this->admin = User::where('role_id', 1)->first();
        $this->customer = User::where('role_id', 2)->first();

        // Buat order awal dengan status Pending (status_id = 1) dan belum bayar
        $this->order = Order::create([
            'user_id' => $this->customer->user_id,
            'event_address' => 'Jl. Balige No. 1',
            'event_latitude' => 2.437,
            'event_longitude' => 99.157,
            'status_id' => 1, // Pending
            'final_price' => 250000.00,
            'order_date' => now(),
            'event_date' => now()->addDays(10),
            'people' => 25,
            'total_paid' => 0.00,
            'is_cancelling' => false
        ]);
    }

    /** @test */
    public function pelanggan_bisa_membatalkan_pesanan_pending_yang_belum_dibayar_secara_langsung()
    {
        $response = $this->actingAs($this->customer, 'sanctum')
            ->postJson("/api/orders/{$this->order->order_id}/cancel");

        $response->assertStatus(200);
        $response->assertJsonPath('message', 'Pesanan berhasil dibatalkan');

        $this->assertDatabaseHas('orders', [
            'order_id' => $this->order->order_id,
            'status_id' => 9 // Cancelled
        ]);
    }

    /** @test */
    public function pelanggan_tidak_bisa_membatalkan_pesanan_pending_secara_langsung_jika_sudah_membayar()
    {
        // Set total_paid > 0
        $this->order->total_paid = 100000.00;
        $this->order->save();

        $response = $this->actingAs($this->customer, 'sanctum')
            ->postJson("/api/orders/{$this->order->order_id}/cancel");

        $response->assertStatus(403);
        $response->assertJsonPath('message', 'Pesanan yang sudah dibayar (walaupun sebagian) tidak bisa dibatalkan secara langsung. Silakan ajukan permintaan pembatalan.');
    }

    /** @test */
    public function pelanggan_bisa_mengajukan_permintaan_pembatalan_pada_pesanan_yang_terkonfirmasi_tapi_belum_dibayar()
    {
        // Ubah status ke 2 (Preparing / Confirmed)
        $this->order->update(['status_id' => 2]);

        $response = $this->actingAs($this->customer, 'sanctum')
            ->postJson("/api/orders/{$this->order->order_id}/request-cancel", [
                'reason' => 'Saya ingin mengganti tanggal acara tetapi tidak bisa.'
            ]);

        $response->assertStatus(200);
        
        $this->assertDatabaseHas('orders', [
            'order_id' => $this->order->order_id,
            'is_cancelling' => true,
            'cancel_reason' => 'Saya ingin mengganti tanggal acara tetapi tidak bisa.'
        ]);
    }

    /** @test */
    public function pelanggan_tidak_bisa_mengajukan_pembatalan_lewat_api_jika_sudah_dibayar()
    {
        // Ubah status ke 2 dan total_paid > 0
        $this->order->status_id = 2;
        $this->order->total_paid = 50000.00;
        $this->order->save();

        $response = $this->actingAs($this->customer, 'sanctum')
            ->postJson("/api/orders/{$this->order->order_id}/request-cancel", [
                'reason' => 'Acara terpaksa dibatalkan.'
            ]);

        $response->assertStatus(400);
        $response->assertJsonPath('message', 'Pesanan yang sudah dibayar tidak dapat dibatalkan lewat aplikasi.');
    }

    /** @test */
    public function admin_bisa_menyetujui_permintaan_pembatalan_dan_mengubah_dp_menjadi_hangus()
    {
        Bus::fake();

        // Siapkan order yang sedang mengajukan pembatalan dan sudah bayar DP
        $order = Order::create([
            'user_id' => $this->customer->user_id,
            'event_address' => 'Jl. Balige No. 2',
            'event_latitude' => 2.437,
            'event_longitude' => 99.157,
            'status_id' => 2,
            'final_price' => 1000000.00,
            'order_date' => now(),
            'event_date' => now()->addDays(10),
            'people' => 50,
            'is_cancelling' => true,
            'cancel_reason' => 'Acara dibatalkan karena hal darurat.'
        ]);
        $order->total_paid = 500000.00;
        $order->save();

        $response = $this->actingAs($this->admin)
            ->post("/admin/orders/{$order->order_id}/cancel-request", [
                'action' => 'approve'
            ]);

        $response->assertStatus(302); // Redirect back
        $response->assertSessionHas('success', 'Pesanan berhasil dibatalkan.');

        // Cek database
        $this->assertDatabaseHas('orders', [
            'order_id' => $order->order_id,
            'status_id' => 9, // Cancelled
            'is_cancelling' => false,
            'total_paid' => 0.00, // Total paid direset ke 0
            'forfeited_amount' => 500000.00 // DP hangus tercatat
        ]);
    }

    /** @test */
    public function admin_bisa_menolak_permintaan_pembatalan()
    {
        // Siapkan order yang mengajukan pembatalan
        $order = Order::create([
            'user_id' => $this->customer->user_id,
            'event_address' => 'Jl. Balige No. 3',
            'event_latitude' => 2.437,
            'event_longitude' => 99.157,
            'status_id' => 2,
            'final_price' => 400000.00,
            'order_date' => now(),
            'event_date' => now()->addDays(10),
            'people' => 20,
            'total_paid' => 0.00,
            'is_cancelling' => true,
            'cancel_reason' => 'Acara batal.'
        ]);

        $response = $this->actingAs($this->admin)
            ->post("/admin/orders/{$order->order_id}/cancel-request", [
                'action' => 'reject'
            ]);

        $response->assertStatus(302);

        // Pastikan status pembatalan dihilangkan tetapi order tidak tercancel
        $this->assertDatabaseHas('orders', [
            'order_id' => $order->order_id,
            'status_id' => 2,
            'is_cancelling' => false
        ]);
    }
}
