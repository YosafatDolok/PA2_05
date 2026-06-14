<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use App\Models\Order;
use Illuminate\Support\Facades\Log;

class CheckoutTokenController extends Controller
{
    /**
     * Generate a signed checkout token for the payment service.
     */
    public function generateToken(Request $request, $id)
    {
        $user = $request->user();
        $order = Order::findOrFail($id);

        // Verify ownership
        if ((int)$order->user_id !== (int)$user->user_id) {
            return response()->json(['message' => 'Anda tidak memiliki akses ke pesanan ini.'], 403);
        }

        // Check if fully paid
        $remainingBalance = (float)$order->remaining_balance;
        if ($remainingBalance <= 0) {
            return response()->json(['message' => 'Pesanan ini sudah lunas.'], 400);
        }

        // Calculate minimum payment allowed
        $totalPayable = (float)$order->total_payable;
        $totalPaid = (float)$order->total_paid;
        
        $minTotalDp = $totalPayable * 0.5;
        $shortfall = $minTotalDp - $totalPaid;
        
        $minPaymentAllowed = max(10000, $shortfall); // Midtrans min is 10k
        
        if ($minPaymentAllowed > $remainingBalance) {
            $minPaymentAllowed = $remainingBalance;
        }

        // Create Payload
        $payload = [
            'order_id' => $order->order_id,
            'user_id' => $order->user_id,
            'user_name' => $user->name,
            'user_email' => $user->email,
            'user_phone' => $user->phone_number,
            'remaining_balance' => $remainingBalance,
            'min_payment_allowed' => $minPaymentAllowed,
            'exp' => time() + (15 * 60) // Token valid for 15 minutes
        ];

        // Sign Payload
        $secretKey = config('services.internal_key', 'PARDEDE_INTERNAL_SECRET_2026');

        $base64Payload = base64_encode(json_encode($payload));
        $signature = hash_hmac('sha256', $base64Payload, $secretKey);

        $token = $base64Payload . '.' . $signature;

        return response()->json([
            'checkout_token' => $token,
            'expires_in' => 15 * 60,
            'remaining_balance' => $remainingBalance,
            'min_payment_allowed' => $minPaymentAllowed
        ]);
    }
}
