<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Order;
use App\Models\DriverLocation;
use App\Models\DeliveryMessage;
use App\Http\Resources\DeliveryInboxResource;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;
use Carbon\Carbon;

class DriverController extends Controller
{
    /**
     * 1. GET ASSIGNED ORDERS
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
     * Get active delivery chats for the driver inbox.
     */
    public function inbox(Request $request)
    {
        $driverId = $request->user()->user_id;

        // 1. Get unique order IDs that have delivery messages
        $orderIds = DeliveryMessage::distinct()->pluck('order_id');

        // 2. Fetch orders specifically assigned to this driver
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
     * 2. UPDATE GPS LOCATION
     */
    public function updateLocation(Request $request)
    {
        if ($request->user()->role_id != 3) {
            return response()->json(['message' => 'Unauthorized. Drivers only.'], 403);
        }

        $request->validate([
            'latitude' => 'required|numeric',
            'longitude' => 'required|numeric',
        ]);

        $location = DriverLocation::updateOrCreate(
            ['user_id' => $request->user()->user_id],
            [
                'latitude' => $request->latitude,
                'longitude' => $request->longitude,
                'updated_at' => now(),
            ]
        );

        return response()->json(['message' => 'Location updated', 'data' => $location]);
    }

    /**
     * 3. UPDATE TRIP STATUS & PROOF
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

        $order->status_id = $request->status_id;

        // Logistics Timestamps
        if ($request->status_id == 3) { // 3 is "Out for Delivery"
            $order->started_delivery_at = now();
        } elseif ($request->status_id == 4) { // 4 is "Delivered"
            if (!$order->delivered_at) {
                $order->delivered_at = now();
            }
            
            if ($request->hasFile('proof_image')) {
                $path = $request->file('proof_image')->store('delivery_proofs', 'public');
                $order->delivery_proof_image = $path;
            }

            // AUTO-PAID: Auto-finalize to Paid (5) if the order is fully paid online
            if ($order->remaining_balance <= 0) {
                $order->status_id = 5; // Paid
            }
        }

        $order->save();

        return response()->json(['message' => 'Status updated', 'order' => $order]);
    }
}
