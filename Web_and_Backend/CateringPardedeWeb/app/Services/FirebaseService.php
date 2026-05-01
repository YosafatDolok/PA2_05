<?php

namespace App\Services;

use Google\Auth\Credentials\ServiceAccountCredentials;
use Google\Auth\HttpHandler\HttpHandlerFactory;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;

class FirebaseService
{
    protected $credentialsPath;

    public function __construct()
    {
        // Place your Firebase Service Account JSON file here
        $this->credentialsPath = storage_path('app/firebase-auth.json');
    }

    public function sendNotification($deviceToken, $title, $body, $data = [])
    {
        if (!file_exists($this->credentialsPath)) {
            Log::warning('Firebase Service Account file not found at: ' . $this->credentialsPath);
            return false;
        }

        try {
            $credentials = new ServiceAccountCredentials(
                'https://www.googleapis.com/auth/cloud-platform',
                $this->credentialsPath
            );

            $token = $credentials->fetchAuthToken(HttpHandlerFactory::build());
            $accessToken = $token['access_token'];

            // Get project_id from the JSON file
            $json = json_decode(file_get_contents($this->credentialsPath), true);
            $projectId = $json['project_id'];

            $url = "https://fcm.googleapis.com/v1/projects/{$projectId}/messages:send";

            $response = Http::withToken($accessToken)->post($url, [
                'message' => [
                    'token' => $deviceToken,
                    'notification' => [
                        'title' => $title,
                        'body' => $body,
                    ],
                    'data' => $data,
                    'android' => [
                        'priority' => 'high',
                        'notification' => [
                            'sound' => 'default',
                        ],
                    ],
                ],
            ]);

            if ($response->successful()) {
                return true;
            }

            Log::error('FCM Send Error: ' . $response->body());
            return false;

        } catch (\Exception $e) {
            Log::error('Firebase Service Exception: ' . $e->getMessage());
            return false;
        }
    }
}
