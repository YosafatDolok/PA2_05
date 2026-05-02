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
        // 1. Get unique order IDs that have messages
        // We use a raw query check to ensure we get everything regardless of soft deletes or scopes
        $orderIds = OrderMessage::distinct()->pluck('order_id');

        // 2. Fetch orders bypassing all filters, specifically for the admin inbox
        $conversations = Order::withoutGlobalScopes()
            ->whereIn('order_id', $orderIds)
            ->with(['user', 'latestMessage'])
            ->withCount(['messages as unread_count' => function ($query) {
                $query->where('is_read', false)
                      ->where('sender_id', '!=', auth()->id());
            }])
            ->get()
            ->sortByDesc(function ($order) {
                // Sort by the latest message time or the order update time
                return $order->latestMessage?->created_at ?? $order->updated_at;
            })
            ->values();

        return ChatInboxResource::collection($conversations);
    }
}
