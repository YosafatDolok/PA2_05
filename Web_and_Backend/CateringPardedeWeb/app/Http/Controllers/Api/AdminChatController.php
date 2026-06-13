<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Resources\ChatInboxResource;
use App\Models\Order;
use App\Models\OrderMessage;
use Illuminate\Http\Request;

class AdminChatController extends Controller
{
    /**
     * Get a list of all active conversations for the admin inbox.
     */
    public function inbox(Request $request)
    {
        $user = auth()->user();
        $roleId = (int)$user->role_id;

        // 🛡️ Security Guardrail: Only Admin (1) and Customer (2) can access this endpoint. Drivers (3) have their own.
        if ($roleId !== 1 && $roleId !== 2) {
            return response()->json(['message' => 'Unauthorized'], 403);
        }

        if ($roleId === 1) {
            // Admin Inbox: all conversations
            $orderIds = OrderMessage::distinct()->pluck('order_id');

            $conversations = Order::withoutGlobalScopes()
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
        } else {
            // Customer Inbox: only their own orders with messages
            $conversations = Order::where('user_id', $user->user_id)
                ->whereHas('messages')
                ->with(['latestMessage'])
                ->withCount(['messages as unread_count' => function ($query) {
                    $query->where('is_read', false)
                          ->where('sender_id', '!=', auth()->id());
                }])
                ->get()
                ->sortByDesc(function ($order) {
                    return $order->latestMessage?->created_at ?? $order->updated_at;
                })
                ->values();
        }

        return ChatInboxResource::collection($conversations);
    }
}
