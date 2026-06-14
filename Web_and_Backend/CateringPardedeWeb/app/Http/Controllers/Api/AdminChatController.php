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
                
            return ChatInboxResource::collection($conversations);
        } else {
            // Customer Inbox: merge order messages (Admin) and delivery messages (Driver)
            $orders = Order::where('user_id', $user->user_id)
                ->where(function($q) {
                    $q->has('messages')->orHas('deliveryMessages');
                })
                ->with(['latestMessage', 'latestDeliveryMessage', 'driver'])
                ->withCount([
                    'messages as unread_order_count' => function ($query) {
                        $query->where('is_read', false)->where('sender_id', '!=', auth()->id());
                    },
                    'deliveryMessages as unread_delivery_count' => function ($query) {
                        $query->where('is_read', false)->where('sender_id', '!=', auth()->id());
                    }
                ])
                ->get();
                
            $inboxItems = collect();
            
            foreach ($orders as $order) {
                if ($order->latestMessage) {
                    $inboxItems->push([
                        'order_id' => $order->order_id,
                        'chat_type' => 'admin',
                        'user' => [
                            'name' => 'Catering Admin',
                            'profile_picture' => null
                        ],
                        'latest_message' => [
                            'message' => $order->latestMessage->message,
                            'created_at' => $order->latestMessage->created_at->toIso8601String(),
                        ],
                        'unread_count' => (int) $order->unread_order_count,
                        'updated_at' => $order->updated_at->toIso8601String()
                    ]);
                }
                
                if ($order->latestDeliveryMessage) {
                    $inboxItems->push([
                        'order_id' => $order->order_id,
                        'chat_type' => 'driver',
                        'user' => [
                            'name' => 'Driver ' . ($order->driver->name ?? 'Unknown'),
                            'profile_picture' => $order->driver->profile_picture ?? null
                        ],
                        'latest_message' => [
                            'message' => $order->latestDeliveryMessage->message,
                            'created_at' => $order->latestDeliveryMessage->created_at->toIso8601String(),
                        ],
                        'unread_count' => (int) $order->unread_delivery_count,
                        'updated_at' => $order->updated_at->toIso8601String()
                    ]);
                }
            }

            return response()->json([
                'data' => $inboxItems->sortByDesc(function ($item) {
                    return $item['latest_message']['created_at'];
                })->values()
            ]);
        }
    }
}
