<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Order;
use App\Models\OrderItem;
use App\Models\OrderMessage;
use App\Models\Notification;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Validator;

class OrderController extends Controller
{
    public function index(Request $request)
    {
        $orders = Order::with(['status', 'driver', 'items.menu'])
            ->withCount(['messages as unread_messages_count' => function ($query) {
                $query->where('is_read', false)
                      ->where('sender_id', '!=', auth()->id());
            }])
            ->when((int)$request->user()->role_id !== 1, function($query) use ($request) {
                return $query->where('user_id', $request->user()->user_id);
            })
            ->when($request->filter === 'pending_proposal', function($query) {
                return $query->where('final_price', 0)->where('status_id', '!=', 5);
            })
            ->when($request->filter === 'unread_chat', function($query) {
                return $query->whereHas('messages', function($q) {
                    $q->where('is_read', false)->where('sender_id', '!=', auth()->id());
                });
            })
            ->orderBy('order_date', 'desc')
            ->get();

        return response()->json($orders);
    }

    public function inbox(Request $request)
    {
        // Fetch all unique order IDs that have messages
        $orderIds = OrderMessage::distinct()->pluck('order_id');

        // Fetch those orders bypassing ALL filters and scopes
        $inbox = Order::withoutGlobalScopes()
            ->whereIn('order_id', $orderIds)
            ->with(['user', 'latestMessage'])
            ->withCount(['messages as unread_count' => function ($query) {
                $query->where('is_read', false)
                      ->where('sender_id', '!=', auth()->id());
            }])
            ->get()
            ->sortByDesc(function ($order) {
                return $order->latestMessage?->created_at ?? $order->updated_at;
            })
            ->values();

        return response()->json($inbox);
    }

    public function store(Request $request)
    {
        // Security: Prevent Admins from placing orders
        if ((int)$request->user()->role_id === 1) {
            return response()->json(['message' => 'Admin tidak diizinkan untuk membuat pesanan.'], 403);
        }

        Log::info('Order Submission:', $request->all());
        $validator = Validator::make($request->all(), [
            'event_address' => 'required|string',
            'event_date' => 'required|date|after_or_equal:today',
            'people' => 'required|integer|min:1',
            'notes' => 'nullable|string',
            'items' => 'required|array|min:1',
            'items.*.menu_id' => 'required|exists:menus,menu_id',
            'items.*.quantity' => 'nullable|integer|min:1',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'message' => 'Validasi gagal: ' . implode(', ', $validator->errors()->all()),
                'errors' => $validator->errors()
            ], 422);
        }

        // Check availability
        $menuIds = collect($request->items)->pluck('menu_id')->toArray();
        $unavailableMenus = \App\Models\Menu::whereIn('menu_id', $menuIds)
            ->where('available', false)
            ->pluck('name');

        if ($unavailableMenus->isNotEmpty()) {
            return response()->json([
                'message' => 'Beberapa menu sedang tidak tersedia: ' . $unavailableMenus->implode(', ')
            ], 422);
        }

        $order = Order::create([
            'user_id' => $request->user()->user_id,
            'event_address' => $request->event_address,
            'event_latitude' => $request->event_latitude,
            'event_longitude' => $request->event_longitude,
            'location_notes' => $request->location_notes,
            'event_date' => $request->event_date,
            'status_id' => 1, // Pending
            'final_price' => null,
            'people' => $request->people,
            'notes' => $request->notes,
        ]);

        // Create Order Items
        foreach ($request->items as $item) {
            OrderItem::create([
                'order_id' => $order->order_id,
                'menu_id' => $item['menu_id'],
                'final_price' => null,
            ]);
        }

        // Notify Admin
        \App\Models\Notification::create([
            'user_id' => 1, // Admin
            'type' => 'new_order',
            'title' => 'Pesanan Baru #' . $order->order_id,
            'message' => $request->user()->name . ' baru saja memesan katering.',
            'related_id' => $order->order_id,
        ]);

        return response()->json([
            'message' => 'Order created successfully',
            'order' => $order->load(['status', 'items.menu'])
        ], 201);
    }

    public function show($id, Request $request)
    {
        $order = Order::with(['status', 'driver', 'items.menu'])
            ->withCount(['messages as unread_messages_count' => function ($query) {
                $query->where('is_read', false)
                      ->where('sender_id', '!=', auth()->id());
            }])
            ->when((int)$request->user()->role_id !== 1, function($query) use ($request) {
                return $query->where('user_id', $request->user()->user_id);
            })
            ->findOrFail($id);

        return response()->json($order);
    }

    public function cancel($id, Request $request)
    {
        $order = Order::where('user_id', $request->user()->user_id)
            ->findOrFail($id);

        // Only allow cancellation if status is Pending (1)
        if ($order->status_id != 1) {
            return response()->json([
                'message' => 'Pesanan tidak dapat dibatalkan karena sudah diproses admin.'
            ], 400);
        }

        $order->update([
            'status_id' => 9 // Cancelled
        ]);

        // Notify Admin
        \App\Models\Notification::create([
            'user_id' => 1, // Admin
            'type' => 'system',
            'title' => 'Pesanan Dibatalkan #' . $order->order_id,
            'message' => $request->user()->name . ' membatalkan pesanannya.',
            'related_id' => $order->order_id,
        ]);

        return response()->json([
            'message' => 'Pesanan berhasil dibatalkan',
            'order' => $order->load(['status', 'items.menu'])
        ]);
    }

    public function updateStatus(Request $request, $id)
{
    Log::info('Update Status from Payment Service', $request->all());

    $request->validate([
        'status_id' => 'required|integer'
    ]);

    $order = Order::findOrFail($id);

    $order->status_id = $request->status_id;
    $order->save();

    return response()->json([
        'message' => 'Status updated successfully',
        'order' => $order
    ]);
}
}
