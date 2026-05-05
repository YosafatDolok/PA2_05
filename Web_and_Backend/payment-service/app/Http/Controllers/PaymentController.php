<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use App\Models\Payment;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;
use Midtrans\Config;
use Midtrans\Snap;

class PaymentController extends Controller
{
    /**
     * 🔥 CREATE TRANSACTION (dipanggil dari Flutter)
     */
    public function createTransaction(Request $request)
    {
        // Midtrans Config
        Config::$serverKey = env('MIDTRANS_SERVER_KEY');
        Config::$isProduction = false;
        Config::$isSanitized = true;
        Config::$is3ds = true;

        // Simpan ke database
        $payment = Payment::create([
            'order_id' => $request->order_id,
            'amount' => $request->amount,
            'payment_method' => 'midtrans',
            'status' => 'pending',
            'external_id' => 'ORDER-' . uniqid(),
        ]);

        // Midtrans params
        $params = [
            'transaction_details' => [
                'order_id' => $payment->external_id,
                'gross_amount' => (int) $payment->amount,
            ],
        ];

        // Generate Snap Token
        $snapToken = Snap::getSnapToken($params);

        return response()->json([
            'snap_token' => $snapToken
        ]);
    }

    /**
     * 🔥 CALLBACK dari Midtrans (AUTO UPDATE)
     */
    public function callback(Request $request)
    {
        $data = $request->all();

        Log::info('MIDTRANS CALLBACK:', $data);

        $externalId = $data['order_id'] ?? null;

        if (!$externalId) {
            return response()->json(['message' => 'No order_id'], 400);
        }

        // Cari payment
        $payment = Payment::where('external_id', $externalId)->first();

        if (!$payment) {
            return response()->json(['message' => 'Payment not found'], 404);
        }

        // Jika pembayaran sukses
        if ($data['transaction_status'] == 'settlement') {

            $payment->status = 'paid';
            $payment->save();

            // 🔥 Kirim ke ORDER SERVICE
            $response = Http::patch(
                "http://10.0.2.2:8000/api/orders/" . $payment->order_id . "/status",
                [
                    'status_id' => 5 // pastikan 5 = Paid di database kamu
                ]
            );

            Log::info('UPDATE ORDER RESPONSE', [
                'status' => $response->status(),
                'body' => $response->body()
            ]);
        }

        return response()->json(['message' => 'Callback handled']);
    }
}