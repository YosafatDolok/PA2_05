<?php

namespace App\Jobs;

use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Foundation\Queue\Queueable;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;

class NotifyOrderServiceJob implements ShouldQueue
{
    use Queueable;

    public $tries = 5;

    public $backoff = [10, 30, 60, 120, 300]; // Coba kembali setelah 10 detik, 30 detik, 1 menit, 2 menit, 5 menit

    /**
     * Inisialisasi job
     */
    public function __construct(
        protected int $orderId,
        protected string $paymentStatus,
        protected float $amount,
        protected string $externalId
    ) {}

    /**
     * Jalankan tugas pengiriman status
     */
    public function handle(): void
    {
        $response = Http::withHeaders([
            'X-Internal-Secret' => env('INTERNAL_SERVICE_KEY', 'default_secret_key'),
            'Accept' => 'application/json'
        ])->post(
            env('MAIN_APP_URL', 'http://localhost:8000') . "/api/orders/" . $this->orderId . "/payments",
            [
                'payment_status' => $this->paymentStatus,
                'amount' => $this->amount,
                'external_id' => $this->externalId
            ]
        );

        if ($response->failed()) {
            Log::warning('FAILED TO NOTIFY ORDER SERVICE. STATUS CODE: ' . $response->status(), [
                'order_id' => $this->orderId,
                'payment_status' => $this->paymentStatus,
                'response' => $response->body()
            ]);

            throw new \Exception('Order Service status update failed with status ' . $response->status());
        }

        Log::info('ORDER SERVICE NOTIFIED VIA QUEUED JOB', [
            'status' => $response->status(),
            'order_id' => $this->orderId,
            'payment_status' => $this->paymentStatus
        ]);
    }
}
