<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Order;
use App\Models\DeliveryMessage;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use App\Services\FirebaseService;
use App\Events\DeliveryMessageSent;

class DeliveryChatController extends Controller
{
    public function index($orderId)
    {
        $order = Order::findOrFail($orderId);

        // Ensure user is authorized (Customer or Driver)
        if ((int)$order->user_id !== (int)Auth::id() && (int)$order->driver_id !== (int)Auth::id()) {
            return response()->json(['message' => 'Unauthorized'], 403);
        }

        $messages = $order->deliveryMessages()
            ->with('sender:user_id,name,profile_picture,role_id')
            ->oldest()
            ->get();

        return response()->json($messages);
    }

    public function store(Request $request, $orderId)
    {
        $order = Order::findOrFail($orderId);

        // Ensure user is authorized (Customer or Driver)
        if ((int)$order->user_id !== (int)Auth::id() && (int)$order->driver_id !== (int)Auth::id()) {
            return response()->json(['message' => 'Unauthorized'], 403);
        }

        $request->validate([
            'message' => 'required|string',
        ]);

        $message = $order->deliveryMessages()->create([
            'sender_id' => Auth::id(),
            'message' => $request->message,
            'is_read' => false,
        ]);

        // Broadcast the message
        broadcast(new DeliveryMessageSent($message))->toOthers();

        // Send Push Notification via FCM
        $recipientId = null;
        if ((int)Auth::id() === (int)$order->user_id) {
            // Sender is Customer, recipient is Driver
            $recipientId = $order->driver_id;
        } else {
            // Sender is Driver, recipient is Customer
            $recipientId = $order->user_id;
        }

        if ($recipientId) {
            $recipient = \App\Models\User::find($recipientId);
            if ($recipient && $recipient->fcm_token) {
                dispatch(new \App\Jobs\SendPushNotification(
                    $recipient->fcm_token,
                    'Pesan Pengiriman: Order #' . $order->order_id,
                    Auth::user()->name . ': ' . $request->message,
                    ['order_id' => (string)$order->order_id, 'type' => 'delivery_chat']
                ))->afterResponse();
            }
        }

        return response()->json($message->load('sender:user_id,name,profile_picture,role_id'), 201);
    }

    public function markAsRead($orderId)
    {
        $order = Order::findOrFail($orderId);

        // Mark all messages from others as read
        $order->deliveryMessages()
            ->where('sender_id', '!=', Auth::id())
            ->where('is_read', false)
            ->update(['is_read' => true]);

        return response()->json(['message' => 'Messages marked as read']);
    }
}
