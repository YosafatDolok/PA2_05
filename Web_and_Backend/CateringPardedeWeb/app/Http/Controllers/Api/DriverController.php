<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Order;
use App\Models\DriverLocation;
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
        } elseif ($request->status_id == 4 || $request->status_id == 5) { // 4 is "Delivered", 5 is "Paid"
            if (!$order->delivered_at) {
                $order->delivered_at = now();
            }
            
            if ($request->hasFile('proof_image')) {
                $path = $request->file('proof_image')->store('delivery_proofs', 'public');
                $order->delivery_proof_image = $path;
            }

            // AUTO-PAID / CASH-PAID TRANSITION
            if ($request->status_id == 5) {
                // If explicitly marked as Paid by the driver (meaning they collected cash/transfer)
                if ($order->total_paid < $order->total_payable) {
                    $order->total_paid = $order->total_payable;
                }
            } else {
                // Otherwise, check if it was already prepaid online
                if ($order->remaining_balance <= 0) {
                    $order->status_id = 5; // Paid
                }
            }
        }

        $order->save();

        return response()->json(['message' => 'Status updated', 'order' => $order]);
    }
}
