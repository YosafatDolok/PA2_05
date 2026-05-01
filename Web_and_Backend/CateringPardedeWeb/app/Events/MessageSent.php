<?php

namespace App\Events;

use App\Models\OrderMessage;
use Illuminate\Broadcasting\Channel;
use Illuminate\Broadcasting\InteractsWithSockets;
use Illuminate\Broadcasting\PrivateChannel;
use Illuminate\Contracts\Broadcasting\ShouldBroadcast;
use Illuminate\Foundation\Events\Dispatchable;
use Illuminate\Queue\SerializesModels;

class MessageSent implements ShouldBroadcast
{
    use Dispatchable, InteractsWithSockets, SerializesModels;

    public $message;

    public function __construct(OrderMessage $message)
    {
        $this->message = $message;
    }

    public function broadcastAs(): string
    {
        return 'message.sent';
    }

    public function broadcastOn(): array
    {
        return [
            new PrivateChannel('order.' . $this->message->order_id),
        ];
    }

    public function broadcastWith(): array
    {
        return [
            'message_id' => $this->message->message_id,
            'order_id' => $this->message->order_id,
            'sender_id' => $this->message->sender_id,
            'message' => $this->message->message,
            'type' => $this->message->type,
            'proposed_price' => $this->message->proposed_price,
            'proposal_status' => $this->message->proposal_status,
            'created_at' => $this->message->created_at->toDateTimeString(),
            'sender' => [
                'user_id' => $this->message->sender->user_id,
                'name' => $this->message->sender->name,
                'profile_picture' => $this->message->sender->profile_picture,
                'role' => [
                    'name' => $this->message->sender->role->name,
                ],
            ],
        ];
    }
}
