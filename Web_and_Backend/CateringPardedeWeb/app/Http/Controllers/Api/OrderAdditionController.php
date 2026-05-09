<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Order;
use App\Models\OrderAdditionRequest;
use App\Models\OrderAdditionItem;
use App\Models\Notification;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Validator;

class OrderAdditionController extends Controller
{
    public function store($orderId, Request $request)
    {
        $validator = Validator::make($request->all(), [
            'menu_ids' => 'required|array|min:1',
            'menu_ids.*' => 'required|exists:menus,menu_id',
            'notes' => 'nullable|string',
        ]);

        if ($validator->fails()) {
            return response()->json(['message' => 'Validasi gagal', 'errors' => $validator->errors()], 422);
        }

        $order = Order::findOrFail($orderId);
        
        // 🛡️ Security Lock: Only the owner of the order can add items
        if ((int)$order->user_id !== (int)auth()->id()) {
            return response()->json(['message' => 'Akses ditolak. Anda hanya dapat menambah menu pada pesanan Anda sendiri.'], 403);
        }

        // 🛡️ Guardrail: Block additions on orders that are finished or in transit
        // 3: Out for Delivery, 4: Delivered, 9: Cancelled
        if (in_array((int)$order->status_id, [3, 4, 9])) {
            return response()->json([
                'message' => 'Tidak dapat menambah menu karena pesanan sedang dikirim, sudah sampai, atau telah dibatalkan.'
            ], 422);
        }

        // Create the request
        $additionRequest = OrderAdditionRequest::create([
            'order_id' => $order->order_id,
            'status_id' => 1, // Pending
            'notes' => $request->notes,
        ]);

        // Create the items
        foreach ($request->menu_ids as $menuId) {
            OrderAdditionItem::create([
                'request_id' => $additionRequest->id,
                'menu_id' => $menuId,
            ]);
        }

        // Notify Admin
        Notification::create([
            'user_id' => 1, // Admin
            'type' => 'new_order',
            'title' => 'Permintaan Tambahan Menu',
            'message' => $request->user()->name . ' meminta ' . count($request->menu_ids) . ' menu tambahan untuk Order #ORD-' . str_pad($order->order_id, 5, '0', STR_PAD_LEFT),
            'related_id' => $order->order_id,
        ]);

        return response()->json([
            'message' => 'Permintaan tambahan berhasil dikirim',
            'request' => $additionRequest->load('items.menu')
        ], 201);
    }

    public function index($orderId)
    {
        $additions = OrderAdditionRequest::with(['items.menu', 'status'])
            ->where('order_id', $orderId)
            ->orderBy('created_at', 'desc')
            ->get();

        return response()->json($additions);
    }

    public function destroy($id)
    {
        $request = OrderAdditionRequest::findOrFail($id);

        // Check if pending
        if ($request->status_id != 1) {
            return response()->json(['message' => 'Hanya permintaan pending yang dapat dibatalkan'], 422);
        }

        $request->delete(); // This will cascade delete items due to migration foreignId cascade

        return response()->json(['message' => 'Permintaan tambahan dibatalkan']);
    }
}
