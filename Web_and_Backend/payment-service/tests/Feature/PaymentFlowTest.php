<?php

namespace Tests\Feature;

use Tests\TestCase;
use App\Models\Payment;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Queue;
use Illuminate\Support\Facades\Log;
use App\Jobs\NotifyOrderServiceJob;
use Mockery;

/**
 * @runTestsInSeparateProcesses
 * @preserveGlobalState disabled
 */
class PaymentFlowTest extends TestCase
{
    use RefreshDatabase;

    protected $kunciRahasia;

    protected function setUp(): void
    {
        parent::setUp();
        $this->kunciRahasia = env('INTERNAL_SERVICE_KEY', 'PARDEDE_INTERNAL_SECRET_2026');
    }

    protected function tearDown(): void
    {
        Mockery::close();
        parent::tearDown();
    }

    protected function generateCheckoutToken($payload)
    {
        $base64Payload = base64_encode(json_encode($payload));
        $signature = hash_hmac('sha256', $base64Payload, $this->kunciRahasia);
        return $base64Payload . '.' . $signature;
    }

    /** @test */
    public function bisa_menginisialisasi_dan_menyimpan_rekaman_pembayaran()
    {
        $payload = [
            'order_id' => 99,
            'user_name' => 'John Doe',
            'user_email' => 'john@example.com',
            'user_phone' => '0812345678',
            'remaining_balance' => 150000.00,
            'min_payment_allowed' => 75000.00,
            'allowed_amounts' => [
                'dp' => 75000.00,
                'full' => 150000.00
            ],
            'exp' => time() + 900 // 15 menit
        ];

        $token = $this->generateCheckoutToken($payload);

        $response = $this->postJson('/api/payments', [
            'checkout_token' => $token,
            'amount' => 75000.00
        ]);

        $response->assertStatus(201);
        $response->assertJsonStructure([
            'id', 'order_id', 'amount', 'status', 'external_id'
        ]);

        $this->assertDatabaseHas('payments', [
            'order_id' => 99,
            'amount' => 75000.00,
            'status' => 'pending'
        ]);
    }

    /** @test */
    public function menolak_inisialisasi_pembayaran_jika_nominal_tidak_sesuai_pilihan()
    {
        $payload = [
            'order_id' => 99,
            'user_name' => 'John Doe',
            'user_email' => 'john@example.com',
            'user_phone' => '0812345678',
            'remaining_balance' => 150000.00,
            'min_payment_allowed' => 75000.00,
            'allowed_amounts' => [
                'dp' => 75000.00,
                'full' => 150000.00
            ],
            'exp' => time() + 900
        ];

        $token = $this->generateCheckoutToken($payload);

        $response = $this->postJson('/api/payments', [
            'checkout_token' => $token,
            'amount' => 100000.00 // nominal acak/salah
        ]);

        $response->assertStatus(400);
        $response->assertJson([
            'message' => 'Nominal pembayaran harus sesuai dengan pilihan (DP 50% atau Lunas).'
        ]);
    }

    /** @test */
    public function bisa_membuat_transaksi_midtrans_dengan_charge_yang_dimock()
    {
        // 1. Membuat data pembayaran lokal
        $payment = Payment::create([
            'order_id' => 99,
            'amount' => 75000.00,
            'status' => 'pending',
            'external_id' => 'ORD-99-TEST-12345'
        ]);

        // 2. Menandatangani token
        $payload = [
            'order_id' => 99,
            'user_name' => 'John Doe',
            'user_email' => 'john@example.com',
            'user_phone' => '0812345678',
            'remaining_balance' => 150000.00,
            'min_payment_allowed' => 75000.00,
            'allowed_amounts' => [
                'dp' => 75000.00,
                'full' => 150000.00
            ],
            'exp' => time() + 900
        ];
        $token = $this->generateCheckoutToken($payload);

        // 3. Mock pemanggilan statis SDK Midtrans
        $midtransMock = Mockery::mock('alias:\Midtrans\CoreApi');
        $midtransMock->shouldReceive('charge')
            ->once()
            ->withAnyArgs()
            ->andReturn((object) [
                'status_code' => '201',
                'transaction_id' => 'midtrans-tx-999',
                'order_id' => 'ORD-99-TEST-12345',
                'gross_amount' => '75000.00',
                'payment_type' => 'bank_transfer',
                'va_numbers' => [
                    (object) ['bank' => 'bca', 'va_number' => '999888777']
                ]
            ]);

        // 4. Mengirim permintaan API
        $response = $this->postJson("/api/payments/{$payment->id}/midtrans", [
            'checkout_token' => $token,
            'payment_type' => 'bank_transfer',
            'bank' => 'bca'
        ]);

        $response->assertStatus(200);
        $response->assertJson([
            'transaction_id' => 'midtrans-tx-999',
            'bca_va_number' => null, // struktur array va_numbers cocok
        ]);

        $payment->refresh();
        $this->assertEquals('midtrans-tx-999', $payment->midtrans_id);
    }

    /** @test */
    public function memproses_callback_dengan_benar_dan_memicu_job_sinkronisasi()
    {
        Queue::fake();

        // 1. Membuat data pembayaran yang sudah ada
        $payment = Payment::create([
            'order_id' => 101,
            'amount' => 125000.00,
            'status' => 'pending',
            'external_id' => 'ORD-101-TEST'
        ]);

        // 2. Membuat signature yang diharapkan: SHA512(order_id + status_code + gross_amount + server_key)
        $externalId = 'ORD-101-TEST';
        $statusCode = '200';
        $grossAmount = '125000.00';
        $serverKey = env('MIDTRANS_SERVER_KEY', ''); // sandbox/test key
        $signatureKey = hash('sha512', $externalId . $statusCode . $grossAmount . $serverKey);

        $payload = [
            'order_id' => $externalId,
            'status_code' => $statusCode,
            'gross_amount' => $grossAmount,
            'signature_key' => $signatureKey,
            'transaction_id' => 'midtrans-tx-101',
            'payment_type' => 'bank_transfer',
            'transaction_time' => '2026-06-24 20:30:00',
            'transaction_status' => 'settlement'
        ];

        // 3. Memanggil endpoint callback
        $response = $this->postJson('/api/payments/callback', $payload);

        $response->assertStatus(200);
        $response->assertJson(['message' => 'Callback handled']);

        // 4. Memastikan database lokal terupdate
        $payment->refresh();
        $this->assertEquals('paid', $payment->status);
        $this->assertEquals('midtrans-tx-101', $payment->midtrans_id);

        // 5. Memastikan Job sinkronisasi didorong ke antrean (Queue)
        Queue::assertPushed(NotifyOrderServiceJob::class, function ($job) {
            $ref = new \ReflectionClass($job);
            
            $orderIdProp = $ref->getProperty('orderId');
            $orderIdProp->setAccessible(true);
            $orderId = $orderIdProp->getValue($job);

            $paymentStatusProp = $ref->getProperty('paymentStatus');
            $paymentStatusProp->setAccessible(true);
            $paymentStatus = $paymentStatusProp->getValue($job);

            $amountProp = $ref->getProperty('amount');
            $amountProp->setAccessible(true);
            $amount = $amountProp->getValue($job);

            $externalIdProp = $ref->getProperty('externalId');
            $externalIdProp->setAccessible(true);
            $externalId = $externalIdProp->getValue($job);

            return $orderId === 101 &&
                   $paymentStatus === 'settled' &&
                   $amount === 125000.00 &&
                   $externalId === 'ORD-101-TEST';
        });
    }

    /** @test */
    public function menolak_callback_dengan_signature_yang_tidak_valid()
    {
        $payment = Payment::create([
            'order_id' => 102,
            'amount' => 50000.00,
            'status' => 'pending',
            'external_id' => 'ORD-102-TEST'
        ]);

        $payload = [
            'order_id' => 'ORD-102-TEST',
            'status_code' => '200',
            'gross_amount' => '50000.00',
            'signature_key' => 'SIGNATURE_TIDAK_VALID',
            'transaction_status' => 'settlement'
        ];

        $response = $this->postJson('/api/payments/callback', $payload);

        $response->assertStatus(403);
        $response->assertJson(['message' => 'Invalid signature']);

        $payment->refresh();
        $this->assertEquals('pending', $payment->status);
    }
}
