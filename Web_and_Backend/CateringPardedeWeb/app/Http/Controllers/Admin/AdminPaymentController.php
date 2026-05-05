<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Http;

class AdminPaymentController extends Controller
{
    public function index()
    {
        $response = Http::withHeaders([
            'X-Internal-Secret' => config('services.internal_key')
        ])->get(env('PAYMENT_SERVICE_URL', 'http://localhost:8001') . '/api/history');

        $payments = $response->successful() ? $response->json() : [];

        return view('admin.payments.index', compact('payments'));
    }
}
