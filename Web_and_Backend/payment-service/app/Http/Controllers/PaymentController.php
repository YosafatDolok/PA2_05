<?php

namespace App\Http\Controllers;

use App\Models\Payment;
use Illuminate\Http\Request;
use Illuminate\Support\Str;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;
use App\Models\OrderStatus;
use Midtrans\Config;
use Midtrans\Snap;


class PaymentController extends Controller
{
    public function store(Request $request)
    {
        $payment = Payment::create([
            'order_id' => $request->order_id,
            'amount' => $request->amount,
            'payment_method' => 'e-wallet',
            'status' => 'pending',
            'external_id' => Str::uuid(),
        ]);

        return response()->json($payment);
    }

    public function pay($id)
{
    $payment = Payment::findOrFail($id);

    $payment->status = 'paid';
    $payment->save();

    // CALLBACK ke Order Service
    $response = Http::patch('http://10.0.2.2:8000/api/orders/'.$payment->order_id.'/status', [
        'status_id' => 9 // sesuai mapping kamu (Paid = 9)
    ]);

    Log::info('Callback response', [
        'status' => $response->status(),
        'body' => $response->body()
    ]);

    return response()->json([
        'message' => 'Payment success',
        'data' => $payment
    ]);
}

    public function getByOrder($orderId)
{
    $payment = Payment::where('order_id', $orderId)->first();

    return response()->json($payment);
}

public function createTransaction($id)
{
    $payment = Payment::findOrFail($id);

    \Midtrans\Config::$serverKey = config('midtrans.server_key');
    \Midtrans\Config::$isProduction = false;

    $params = [
        'transaction_details' => [
            'order_id' => $payment->external_id,
            'gross_amount' => $payment->amount,
        ],
    ];

    $snapToken = \Midtrans\Snap::getSnapToken($params);

    return response()->json([
        'snap_token' => $snapToken
    ]);
}
}
