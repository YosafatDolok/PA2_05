<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Order;
use App\Models\DeliveryMessage;
use App\Http\Resources\DeliveryInboxResource;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;
use Carbon\Carbon;

class DriverController extends Controller
{
    /**
     * Ambil pesanan yang ditugaskan kepada driver.
     */
    public function myOrders(Request $request)
    {
        $orders = Order::where('driver_id', $request->user()->user_id)
            ->with(['user', 'status', 'items.menu'])
            ->orderBy('event_date', 'asc')
            ->get();

        return response()->json($orders);
    }

    /**
     * Ambil percakapan pengantaran yang aktif untuk kotak masuk driver.
     */
    public function inbox(Request $request)
    {
        $driverId = $request->user()->user_id;

        //Ambil daftar order_id unik yang memiliki pesan pengantaran
        $orderIds = DeliveryMessage::distinct()->pluck('order_id');

        //Ambil pesanan yang secara khusus ditugaskan kepada driver ini
        $conversations = Order::where('driver_id', $driverId)
            ->whereIn('order_id', $orderIds)
            ->with(['user', 'latestDeliveryMessage'])
            ->withCount(['deliveryMessages as unread_count' => function ($query) use ($driverId) {
                $query->where('is_read', false)
                      ->where('sender_id', '!=', $driverId);
            }])
            ->get()
            ->sortByDesc(function ($order) {
                return $order->latestDeliveryMessage?->created_at ?? $order->updated_at;
            })
            ->values();

        return DeliveryInboxResource::collection($conversations);
    }



    /**
     * Perbarui status pengantaran dan bukti pengiriman.
     */
    public function updateStatus(Request $request, $id)
    {
        $order = Order::where('order_id', $id)
            ->where('driver_id', $request->user()->user_id)
            ->firstOrFail();

        $request->validate([
            'status_id' => 'required|exists:order_statuses,status_id',
            'proof_image' => 'nullable|image|max:5120', // Max 5MB
        ]);

        // Validasi Pembayaran (defense-in-depth)
        if (in_array((int)$request->status_id, [2, 3, 4, 5])) {
            if ((float)$order->total_payable <= 0) {
                return response()->json(['message' => 'Pesanan tidak dapat diproses karena harga final belum ditentukan oleh Admin.'], 400);
            }
            
            $minRequired = (float)$order->total_payable * 0.5;
            if ((float)$order->total_paid < $minRequired) {
                return response()->json([
                    'message' => 'Pesanan tidak dapat diproses karena pembayaran belum mencapai minimal DP 50% atau Lunas.'
                ], 400);
            }
        }

        $order->status_id = $request->status_id;

        // Logistics Timestamps
        if ($request->status_id == 3) { // 3 adalah "Out for Delivery"
            $order->started_delivery_at = now();
        } elseif ($request->status_id == 4) { // 4 adalah "Delivered"
            if (!$order->delivered_at) {
                $order->delivered_at = now();
            }
            
            if ($request->hasFile('proof_image')) {
                $path = $request->file('proof_image')->store('delivery_proofs', 'public');
                $order->delivery_proof_image = $path;
            }

            // Pembayaran Otomatis: Ubah status menjadi Lunas (5) jika pesanan telah dibayar penuh secara online
            if ($order->remaining_balance <= 0) {
                $order->status_id = 5; // Paid
            }
        }

        $order->save();

        return response()->json(['message' => 'Status updated', 'order' => $order]);
    }
}
