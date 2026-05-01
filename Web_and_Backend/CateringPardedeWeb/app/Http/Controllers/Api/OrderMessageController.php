<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Order;
use App\Models\OrderMessage;
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
            'type' => 'nullable|string|in:text,proposal',
            'proposed_price' => 'nullable|numeric|min:0',
        ]);

        $message = $order->messages()->create([
            'sender_id' => Auth::id(),
            'message' => $request->message,
            'is_read' => false,
            'type' => $request->type ?? 'text',
            'proposed_price' => $request->proposed_price,
            'proposal_status' => ($request->type === 'proposal') ? 'pending' : null,
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
            try {
                $fcmService = new \App\Services\FirebaseService();
                $fcmService->sendNotification(
                    $recipient->fcm_token,
                    'Pesan Baru: Order #' . $order->order_id,
                    Auth::user()->name . ': ' . $request->message,
                    ['order_id' => (string)$order->order_id]
                );
            } catch (\Exception $e) {
                \Log::error('FCM Notification Error: ' . $e->getMessage());
            }
        }

        return response()->json($message->load('sender:user_id,name,profile_picture'), 201);
    }

    public function acceptProposal($orderId, $messageId)
    {
        $order = Order::findOrFail($orderId);
        $message = OrderMessage::findOrFail($messageId);

        // Only the order owner or admin can accept a proposal
        if ((int)Auth::user()->role_id !== 1 && (int)$order->user_id !== (int)Auth::id()) {
            return response()->json(['message' => 'Unauthorized'], 403);
        }

        if ($message->type !== 'proposal' || $message->proposal_status !== 'pending') {
            return response()->json(['message' => 'Invalid proposal'], 400);
        }

        $message->update(['proposal_status' => 'accepted']);
        
        // Update the order final price
        $order->update(['final_price' => $message->proposed_price]);

        // Broadcast the status update so the other side sees it accepted
        broadcast(new \App\Events\MessageSent($message->load('sender.role')))->toOthers();

        return response()->json(['message' => 'Proposal accepted', 'order' => $order]);
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
}
