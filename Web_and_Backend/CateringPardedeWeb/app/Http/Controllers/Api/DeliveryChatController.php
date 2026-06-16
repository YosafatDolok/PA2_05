<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Order;
use App\Models\DeliveryMessage;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use App\Services\FirebaseService;
use App\Events\DeliveryMessageSent;
use App\Events\DeliveryMessageDeleted;

class DeliveryChatController extends Controller
{
    public function index($orderId)
    {
        $order = Order::findOrFail($orderId);

        // Ensure user is authorized (Customer or Driver ONLY)
        if ((int)$order->user_id !== (int)Auth::id() && (int)$order->driver_id !== (int)Auth::id()) {
            return response()->json(['message' => 'Unauthorized'], 403);
        }

        // Include soft-deleted messages so deleted bubbles can be rendered as placeholders
        $messages = $order->deliveryMessages()
            ->withTrashed()
            ->with('sender:user_id,name,profile_picture,role_id')
            ->oldest()
            ->get()
            ->map(function ($msg) {
                return [
                    'message_id' => $msg->message_id,
                    'order_id'   => $msg->order_id,
                    'sender_id'  => $msg->sender_id,
                    'message'    => $msg->deleted_at ? null : $msg->message,
                    'is_read'    => $msg->is_read,
                    'is_deleted' => !is_null($msg->deleted_at),
                    'created_at' => $msg->created_at,
                    'sender'     => $msg->sender,
                ];
            });

        return response()->json($messages);
    }

    public function store(Request $request, $orderId)
    {
        $order = Order::findOrFail($orderId);

        // Ensure user is authorized (Customer or Driver ONLY)
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

        // Send Push Notification via FCM to the OTHER participants
        $recipients = [];
        $senderId = (int)Auth::id();

        // 1. Notify Customer (if sender is not Customer)
        if ($senderId !== (int)$order->user_id) {
            $recipients[] = $order->user_id;
        }

        // 2. Notify Driver (if assigned, and sender is not Driver)
        if ($order->driver_id && $senderId !== (int)$order->driver_id) {
            $recipients[] = $order->driver_id;
        }

        foreach ($recipients as $recipientId) {
            // Defensive check to prevent self-notification
            if ((int)$recipientId === $senderId) {
                continue;
            }

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

    public function destroy($orderId, $messageId)
    {
        $order   = Order::findOrFail($orderId);
        $message = DeliveryMessage::where('order_id', $order->order_id)
            ->findOrFail($messageId);

        // Only the original sender can delete
        if ((int)$message->sender_id !== (int)Auth::id()) {
            return response()->json(['message' => 'Anda hanya dapat menghapus pesan Anda sendiri.'], 403);
        }

        // Can only delete if the receiver has NOT read it yet
        if ($message->is_read) {
            return response()->json(['message' => 'Pesan sudah dibaca dan tidak dapat dihapus.'], 403);
        }

        $message->delete(); // Soft delete — sets deleted_at

        // Notify all other participants' screens in real-time
        broadcast(new DeliveryMessageDeleted($message))->toOthers();

        return response()->json(['success' => true, 'message_id' => $message->message_id]);
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
