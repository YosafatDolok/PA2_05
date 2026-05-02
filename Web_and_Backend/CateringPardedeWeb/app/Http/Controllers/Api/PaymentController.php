<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Order;
use App\Models\Payment;
use App\Services\MidtransService;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Log;

class PaymentController extends Controller
{
    protected $midtransService;

    public function __construct(MidtransService $midtransService)
    {
        $this->midtransService = $midtransService;
    }

    /**
     * Step 1: Create a Snap Token for Checkout
     */
    public function checkout($orderId)
    {
        $order = Order::with(['user', 'items.menu'])->findOrFail($orderId);

        // Check if user is the owner
        if ($order->user_id !== Auth::id()) {
            return response()->json(['message' => 'Unauthorized'], 403);
        }

        if (!$order->final_price) {
            return response()->json(['message' => 'Price not yet negotiated'], 400);
        }

        $snapToken = $this->midtransService->getSnapToken($order);

        if (!$snapToken) {
            return response()->json(['message' => 'Failed to generate payment token'], 500);
        }

        // Record the payment attempt
        Payment::create([
            'order_id' => $order->order_id,
            'amount' => $order->final_price,
            'snap_token' => $snapToken,
            'status' => 'pending'
        ]);

        return response()->json([
            'snap_token' => $snapToken,
            'client_key' => config('midtrans.client_key'),
            'snap_url' => config('midtrans.snap_url')
        ]);
    }

    /**
     * Step 2: Handle Midtrans Webhook (Callback)
     */
    public function callback(Request $request)
    {
        $serverKey = config('midtrans.server_key');
        $hashed = hash("sha512", $request->order_id . $request->status_code . $request->gross_amount . $serverKey);

        if ($hashed !== $request->signature_key) {
            return response()->json(['message' => 'Invalid signature'], 403);
        }

        // Parse order_id (Format: {id}-{timestamp})
        $orderIdParts = explode('-', $request->order_id);
        $orderId = $orderIdParts[0];

        $order = Order::find($orderId);
        if (!$order) {
            return response()->json(['message' => 'Order not found'], 404);
        }

        $status = $request->transaction_status;
        $paymentStatus = 'pending';

        if ($status == 'capture' || $status == 'settlement') {
            $paymentStatus = 'settlement';
            $order->update(['status_id' => 3]); // Assuming 3 is "Paid" or "Processed"
        } else if ($status == 'deny' || $status == 'expire' || $status == 'cancel') {
            $paymentStatus = $status;
        }

        // Update Payment record
        Payment::where('order_id', $orderId)
            ->where('status', 'pending')
            ->update([
                'midtrans_id' => $request->transaction_id,
                'status' => $paymentStatus,
                'payment_type' => $request->payment_type
            ]);

        return response()->json(['message' => 'Callback handled']);
    }
}
