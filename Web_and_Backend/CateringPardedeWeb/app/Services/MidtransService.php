<?php

namespace App\Services;

use Midtrans\Config;
use Midtrans\Snap;
use App\Models\Order;
use Illuminate\Support\Facades\Log;

class MidtransService
{
    public function __construct()
    {
        Config::$serverKey = config('midtrans.server_key');
        Config::$isProduction = config('midtrans.is_production');
        Config::$isSanitized = config('midtrans.is_sanitized');
        Config::$is3ds = config('midtrans.is_3ds');
    }

    public function getSnapToken(Order $order)
    {
        $params = [
            'transaction_details' => [
                'order_id' => $order->order_id . '-' . time(),
                'gross_amount' => (int) $order->final_price,
            ],
            'customer_details' => [
                'first_name' => $order->user->name,
                'email' => $order->user->email,
                'phone' => $order->user->phone_number,
            ],
            'item_details' => $order->items->map(function ($item) {
                return [
                    'id' => $item->menu_id,
                    'price' => (int) $item->price,
                    'quantity' => $item->quantity,
                    'name' => $item->menu->name,
                ];
            })->toArray(),
        ];

        try {
            $snapToken = Snap::getSnapToken($params);
            return $snapToken;
        } catch (\Exception $e) {
            Log::error('Midtrans Snap Token Error: ' . $e->getMessage());
            return null;
        }
    }
}
