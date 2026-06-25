<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use App\Models\Order;
use Illuminate\Support\Facades\Log;

class CheckoutTokenController extends Controller
{
    /**
     * Buat token checkout yang telah ditandatangani untuk layanan pembayaran.
     */
    public function generateToken(Request $request, $id)
    {
        $user = $request->user();
        $order = Order::findOrFail($id);

        //Verifikasi kepemilikan pesanan
        if ((int)$order->user_id !== (int)$user->user_id) {
            return response()->json(['message' => 'Anda tidak memiliki akses ke pesanan ini.'], 403);
        }

        $totalPayable = (float)$order->total_payable;
        $totalPaid = (float)$order->total_paid;
        $remainingBalance = (float)$order->remaining_balance;

        // Periksa apakah harga final sudah dikonfirmasi oleh Admin (hanya untuk pesanan baru/Pending)
        if ((int)$order->status_id === 1 && !$order->is_price_confirmed) {
            return response()->json(['message' => 'Harga pesanan belum dikonfirmasi oleh Admin.'], 400);
        }

        // Periksa apakah harga final belum ditentukan
        if ((float)$order->total_payable <= 0) {
            return response()->json(['message' => 'Harga final pesanan belum ditentukan oleh Admin.'], 400);
        }

        // Periksa apakah pesanan sudah lunas
        if ($remainingBalance <= 0) {
            return response()->json(['message' => 'Pesanan ini sudah lunas.'], 400);
        }

        // Tentukan pilihan pembayaran yang diperbolehkan secara tepat (DP 50% atau Lunas 100%)
        $allowedAmounts = [];
        $minTotalDp = $totalPayable * 0.5;

        if ($totalPaid == 0) {
            $allowedAmounts = [
                'dp' => $minTotalDp,
                'full' => $totalPayable
            ];
            $minPaymentAllowed = $minTotalDp;
        } else {
            $allowedAmounts = [
                'full' => $remainingBalance
            ];
            $minPaymentAllowed = $remainingBalance;
        }

        // Buat payload token
        $payload = [
            'order_id' => $order->order_id,
            'user_id' => $order->user_id,
            'user_name' => $user->name,
            'user_email' => $user->email,
            'user_phone' => $user->phone_number,
            'remaining_balance' => $remainingBalance,
            'min_payment_allowed' => $minPaymentAllowed,
            'allowed_amounts' => $allowedAmounts,
            'exp' => time() + (15 * 60) // Token berlaku selama 15 menit
        ];

        // Tandatangani payload
        $secretKey = config('services.internal_key', 'PARDEDE_INTERNAL_SECRET_2026');

        $base64Payload = base64_encode(json_encode($payload));
        $signature = hash_hmac('sha256', $base64Payload, $secretKey);

        $token = $base64Payload . '.' . $signature;

        return response()->json([
            'checkout_token' => $token,
            'expires_in' => 15 * 60,
            'remaining_balance' => $remainingBalance,
            'min_payment_allowed' => $minPaymentAllowed,
            'allowed_amounts' => $allowedAmounts
        ]);
    }
}
