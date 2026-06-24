<?php

namespace Tests\Feature;

use Tests\TestCase;
use App\Models\User;
use App\Models\Order;
use App\Models\ProcessedPayment;
use Database\Seeders\DatabaseSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;

class ReceivePaymentNotificationTest extends TestCase
{
    use RefreshDatabase;

    protected $pesanan;
    protected $headerRahasia;

    protected function setUp(): void
    {
        parent::setUp();

        $this->seed(DatabaseSeeder::class);

        $pelanggan = User::factory()->create(['role_id' => 2]);
        $this->pesanan = Order::create([
            'user_id' => $pelanggan->user_id,
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

        $this->headerRahasia = [
            'X-Internal-Secret' => config('services.internal_key', 'PARDEDE_INTERNAL_SECRET_2026')
        ];
    }

    /** @test */
    public function menolak_permintaan_tanpa_internal_secret_header()
    {
        $response = $this->postJson("/api/orders/{$this->pesanan->order_id}/payments", [
            'payment_status' => 'settled',
            'amount' => 50000.00,
            'external_id' => 'ORD-1-XYZ-12345'
        ]);

        $response->assertStatus(403);
    }

    /** @test */
    public function menolak_permintaan_dengan_internal_secret_header_yang_salah()
    {
        $response = $this->postJson("/api/orders/{$this->pesanan->order_id}/payments", [
            'payment_status' => 'settled',
            'amount' => 50000.00,
            'external_id' => 'ORD-1-XYZ-12345'
        ], [
            'X-Internal-Secret' => 'TOKEN_SALAH'
        ]);

        $response->assertStatus(403);
    }

    /** @test */
    public function mencatat_pembayaran_dan_memperbarui_total_bayar_pada_settlement_yang_valid()
    {
        $externalId = 'ORD-1-XYZ-12345';
        $response = $this->postJson("/api/orders/{$this->pesanan->order_id}/payments", [
            'payment_status' => 'settled',
            'amount' => 50000.00,
            'external_id' => $externalId
        ], $this->headerRahasia);

        $response->assertStatus(200);
        $response->assertJsonPath('message', 'Notifikasi pembayaran berhasil diproses.');

        $this->pesanan->refresh();
        $this->assertEquals(50000.00, (float)$this->pesanan->total_paid);

        $this->assertDatabaseHas('processed_payments', [
            'order_id' => $this->pesanan->order_id,
            'external_id' => $externalId,
            'amount' => 50000.00
        ]);
    }

    /** @test */
    public function menerapkan_idempotensi_untuk_notifikasi_pembayaran_ganda()
    {
        $externalId = 'ORD-1-DUPLICATE-123';

        // 1. Kirim sinyal pembayaran pertama
        $response1 = $this->postJson("/api/orders/{$this->pesanan->order_id}/payments", [
            'payment_status' => 'settled',
            'amount' => 50000.00,
            'external_id' => $externalId
        ], $this->headerRahasia);
        $response1->assertStatus(200);

        // 2. Kirim sinyal pembayaran duplikat
        $response2 = $this->postJson("/api/orders/{$this->pesanan->order_id}/payments", [
            'payment_status' => 'settled',
            'amount' => 50000.00,
            'external_id' => $externalId
        ], $this->headerRahasia);

        $response2->assertStatus(200);
        $response2->assertJsonPath('message', 'Pembayaran sudah diproses sebelumnya.');

        // Memastikan total bayar tetap 50.000 (tidak menjadi 100.000)
        $this->pesanan->refresh();
        $this->assertEquals(50000.00, (float)$this->pesanan->total_paid);
    }

    /** @test */
    public function menandai_pesanan_sebagai_lunas_jika_sudah_dikirim_dan_lunas()
    {
        // Mengubah status pesanan menjadi Dikirim (status_id = 4)
        $this->pesanan->update([
            'status_id' => 4
        ]);

        $externalId = 'ORD-1-FULL-PAY';
        $response = $this->postJson("/api/orders/{$this->pesanan->order_id}/payments", [
            'payment_status' => 'settled',
            'amount' => 100000.00, // Melunasi seluruh nominal final_price
            'external_id' => $externalId
        ], $this->headerRahasia);

        $response->assertStatus(200);

        $this->pesanan->refresh();
        $this->assertEquals(5, $this->pesanan->status_id); // status_id 5 adalah Lunas (Paid)
    }
}
