<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Http;

class AdminPaymentController extends Controller
{
    public function index()
    {
        $payments = [];

        try {
            $response = Http::withHeaders([
                'X-Internal-Secret' => config('services.internal_key')
            ])->timeout(3)->get(env('PAYMENT_SERVICE_URL', 'http://localhost:8001') . '/api/history');

            if ($response->successful()) {
                $payments = $response->json();
            }
        } catch (\Exception $e) {
            \Illuminate\Support\Facades\Log::warning("Payment History Microservice unavailable: " . $e->getMessage());
        }

        return view('admin.payments.index', compact('payments'));
    }
}
