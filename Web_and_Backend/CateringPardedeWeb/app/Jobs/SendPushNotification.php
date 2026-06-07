<?php

namespace App\Jobs;

use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Foundation\Queue\Queueable;
use Illuminate\Foundation\Bus\Dispatchable;
use Illuminate\Queue\InteractsWithQueue;
use Illuminate\Queue\SerializesModels;

class SendPushNotification implements ShouldQueue
{
    use Dispatchable, InteractsWithQueue, Queueable, SerializesModels;

    protected $deviceToken;
    protected $title;
    protected $body;
    protected $data;

    /**
     * Create a new job instance.
     */
    public function __construct($deviceToken, $title, $body, $data = [])
    {
        $this->deviceToken = $deviceToken;
        $this->title = $title;
        $this->body = $body;
        $this->data = $data;
    }

    /**
     * Execute the job.
     */
    public function handle(): void
    {
        try {
            $fcmService = new \App\Services\FirebaseService();
            $fcmService->sendNotification($this->deviceToken, $this->title, $this->body, $this->data);
        } catch (\Exception $e) {
            \Illuminate\Support\Facades\Log::error('FCM Job Error: ' . $e->getMessage());
        }
    }
}
