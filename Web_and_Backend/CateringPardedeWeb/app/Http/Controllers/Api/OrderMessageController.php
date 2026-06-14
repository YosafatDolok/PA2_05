<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Order;
use App\Models\OrderMessage;
use App\Models\DeliveryMessage;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;

class OrderMessageController extends Controller
{
    public function index($orderId)
    {
        $order = Order::findOrFail($orderId);

        // Debug logging
        \Log::info('OrderMessage index attempt', [
            'auth_user_id' => Auth::id(),
            'auth_role_id' => Auth::user()->role_id,
            'order_id' => $order->order_id,
            'order_user_id' => $order->user_id,
        ]);

        // Ensure user is authorized to see these messages
        if ((int)Auth::user()->role_id !== 1 && (int)$order->user_id !== (int)Auth::id()) {
            return response()->json(['message' => 'Unauthorized'], 403);
        }

        $messages = $order->messages()
            ->with('sender:user_id,name,profile_picture')
            ->oldest()
            ->get();

        return response()->json($messages);
    }

    public function store(Request $request, $orderId)
    {
        $order = Order::findOrFail($orderId);

        // Debug logging
        \Log::info('OrderMessage store attempt', [
            'auth_user_id' => Auth::id(),
            'auth_role_id' => Auth::user()->role_id,
            'order_id' => $order->order_id,
            'order_user_id' => $order->user_id,
        ]);

        // Ensure user is authorized to message about this order
        if ((int)Auth::user()->role_id !== 1 && (int)$order->user_id !== (int)Auth::id()) {
            return response()->json(['message' => 'Unauthorized'], 403);
        }

        $request->validate([
            'message' => 'required|string',
        ]);

        $message = $order->messages()->create([
            'sender_id' => Auth::id(),
            'message' => $request->message,
            'is_read' => false,
        ]);

        // Broadcast the message to others on the channel
        broadcast(new \App\Events\MessageSent($message->load('sender.role')))->toOthers();

        // Send Push Notification via FCM
        $recipientId = null;
        if ((int)Auth::id() === (int)$order->user_id) {
            // Recipient is Admin
            $admin = \App\Models\User::whereHas('role', function($q) {
                $q->where('name', 'admin');
            })->first();
            $recipientId = $admin ? $admin->user_id : null;
        } else {
            // Recipient is Customer
            $recipientId = $order->user_id;
        }

        $recipient = $recipientId ? \App\Models\User::find($recipientId) : null;

        if ($recipient && $recipient->fcm_token) {
            dispatch(new \App\Jobs\SendPushNotification(
                $recipient->fcm_token,
                'Pesan Baru: Order #' . $order->order_id,
                Auth::user()->name . ': ' . $request->message,
                ['order_id' => (string)$order->order_id, 'type' => 'order_chat']
            ))->afterResponse();
        }

        return response()->json($message->load('sender:user_id,name,profile_picture'), 201);
    }



    public function markAsRead($orderId)
    {
        $order = Order::findOrFail($orderId);

        // Mark all messages from others as read
        $order->messages()
            ->where('sender_id', '!=', Auth::id())
            ->where('is_read', false)
            ->update(['is_read' => true]);

        return response()->json(['message' => 'Messages marked as read']);
    }

    public function unreadCount(Request $request)
    {
        $userId = Auth::id();
        $isAdmin = (int)Auth::user()->role_id === 1;

        if ($isAdmin) {
            $count = OrderMessage::where('is_read', false)
                ->where('sender_id', '!=', $userId)
                ->count();
        } else if ((int)Auth::user()->role_id === 3) {
            // Driver
            $count = DeliveryMessage::where('is_read', false)
                ->where('sender_id', '!=', $userId)
                ->whereHas('order', function ($query) use ($userId) {
                    $query->where('driver_id', $userId);
                })
                ->count();
        } else {
            // Customer
            $count = OrderMessage::where('is_read', false)
                ->where('sender_id', '!=', $userId)
                ->whereHas('order', function ($query) use ($userId) {
                    $query->where('user_id', $userId);
                })
                ->count();
            $count += DeliveryMessage::where('is_read', false)
                ->where('sender_id', '!=', $userId)
                ->whereHas('order', function ($query) use ($userId) {
                    $query->where('user_id', $userId);
                })
                ->count();
        }

        return response()->json(['unread_count' => $count]);
    }
}
