<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use App\Models\Payment;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;
use Midtrans\Config;
use Midtrans\Snap;
use Illuminate\Support\Str;

class PaymentController extends Controller
{
    /**
     * 1. INITIALIZE PAYMENT (Called from Flutter)
     */
    public function store(Request $request)
    {
        $request->validate([
            'order_id' => 'required',
            'amount' => 'required|numeric'
        ]);

        $payment = Payment::create([
            'order_id' => $request->order_id,
            'amount' => $request->amount,
            'payment_method' => 'midtrans',
            'status' => 'pending',
            'external_id' => 'ORD-' . $request->order_id . '-' . strtoupper(Str::random(5)) . '-' . time(),
        ]);

        return response()->json($payment, 201);
    }

    /**
     * 2. GENERATE MIDTRANS SNAP TOKEN
     */
    public function createTransaction(Request $request, $id)
    {
        // Get existing payment or create if missing
        $payment = Payment::find($id);
        if (!$payment) {
            return response()->json(['message' => 'Payment record not found'], 404);
        }

        // Midtrans Config
        Config::$serverKey = env('MIDTRANS_SERVER_KEY');
        Config::$isProduction = false;
        Config::$isSanitized = true;
        Config::$is3ds = true;

        // Midtrans params
        $params = [
            'transaction_details' => [
                'order_id' => $payment->external_id,
                'gross_amount' => (int) $payment->amount,
            ],
        ];

        // Generate Snap Token
        try {
            $snapToken = Snap::getSnapToken($params);
            
            // Save token for future use
            $payment->update(['snap_token' => $snapToken]);

            return response()->json([
                'snap_token' => $snapToken
            ]);
        } catch (\Exception $e) {
            return response()->json(['message' => $e->getMessage()], 500);
        }
    }

    /**
     * 3. GET PAYMENT BY ORDER ID
     */
    public function getByOrder($orderId)
    {
        $payment = Payment::where('order_id', $orderId)->first();
        if (!$payment) {
            return response()->json(['message' => 'No payment found for this order'], 404);
        }
        return response()->json($payment);
    }

    /**
     * 4. MIDTRANS CALLBACK (Auto Update with Security)
     */
    public function callback(Request $request)
    {
        $data = $request->all();
        Log::info('MIDTRANS CALLBACK RECEIVED:', $data);

        $externalId = $data['order_id'] ?? null;
        $statusCode = $data['status_code'] ?? '';
        $grossAmount = $data['gross_amount'] ?? '';
        $serverKey = env('MIDTRANS_SERVER_KEY');
        $signatureKey = $data['signature_key'] ?? '';

        // 🛡️ SECURITY STEP 1: Verify Signature
        $signature = hash('sha512', $externalId . $statusCode . $grossAmount . $serverKey);

        if ($signature !== $signatureKey) {
            Log::error('FRAUD ATTEMPT: Invalid Midtrans Signature', ['data' => $data]);
            return response()->json(['message' => 'Invalid signature'], 403);
        }

        // 🛡️ SECURITY STEP 2: Find Payment and Verify Amount
        $payment = Payment::where('external_id', $externalId)->first();
        if (!$payment) {
            return response()->json(['message' => 'Payment not found'], 404);
        }

        if ((int)$payment->amount !== (int)$grossAmount) {
            Log::error('FRAUD ATTEMPT: Amount Mismatch', [
                'expected' => $payment->amount,
                'received' => $grossAmount
            ]);
            return response()->json(['message' => 'Amount mismatch'], 400);
        }

        // Capture rich data from Midtrans
        $payment->midtrans_id = $data['transaction_id'] ?? null;
        $payment->payment_type = $data['payment_type'] ?? null;
        $payment->transaction_time = $data['transaction_time'] ?? null;

        $transactionStatus = $data['transaction_status'];
        $newOrderStatus = null;

        if ($transactionStatus == 'settlement' || $transactionStatus == 'capture') {
            $payment->status = 'paid';
            $newOrderStatus = 5; // Paid
        } elseif ($transactionStatus == 'pending') {
            $payment->status = 'pending';
        } elseif ($transactionStatus == 'deny' || $transactionStatus == 'expire' || $transactionStatus == 'cancel') {
            $payment->status = 'failed';
            $newOrderStatus = 9; // Cancelled
        }

        $payment->save();

        // Notify Main Backend
        if ($newOrderStatus) {
            $this->notifyOrderService($payment->order_id, $newOrderStatus);
        }

        return response()->json(['message' => 'Callback handled']);
    }

    private function notifyOrderService($orderId, $statusId)
    {
        try {
            // Find the last payment for this order to get the amount
            $payment = Payment::where('order_id', $orderId)->latest()->first();
            
            if (!$payment) return;

            $response = Http::withHeaders([
                'X-Internal-Secret' => env('INTERNAL_SERVICE_KEY', 'default_secret_key')
            ])->patch(
                env('MAIN_APP_URL', 'http://localhost:8000') . "/api/orders/" . $orderId . "/status",
                [
                    'status_id' => $statusId,
                    'amount' => $payment->amount,
                    'external_id' => $payment->external_id
                ]
            );

            Log::info('ORDER SERVICE NOTIFIED', [
                'status' => $response->status(),
                'response' => $response->body(),
                'order_id' => $orderId,
                'new_status' => $statusId
            ]);
        } catch (\Exception $e) {
            Log::error('FAILED TO NOTIFY ORDER SERVICE', ['error' => $e->getMessage()]);
        }
    }
}