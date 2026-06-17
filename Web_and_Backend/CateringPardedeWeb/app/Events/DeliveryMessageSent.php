<?php

namespace App\Events;

use App\Models\DeliveryMessage;
use Illuminate\Broadcasting\Channel;
use Illuminate\Broadcasting\InteractsWithSockets;
use Illuminate\Broadcasting\PresenceChannel;
use Illuminate\Broadcasting\PrivateChannel;
use Illuminate\Contracts\Broadcasting\ShouldBroadcastNow;
use Illuminate\Foundation\Events\Dispatchable;
use Illuminate\Queue\SerializesModels;

class DeliveryMessageSent implements ShouldBroadcastNow
{
    use Dispatchable, InteractsWithSockets, SerializesModels;

    public $message;

    public function __construct(DeliveryMessage $message)
    {
        $this->message = $message->load('sender:user_id,name,role_id');
    }

    /**
     *
     *
     * @return array<int, \Illuminate\Broadcasting\Channel>
     */
    public function broadcastOn(): array
    {
        return [
            new PrivateChannel('delivery.order.' . $this->message->order_id),
        ];
    }

    public function broadcastAs()
    {
        return 'delivery.message.sent';
    }

    public function broadcastWith()
    {
        return [
            'message_id' => $this->message->message_id,
            'order_id' => $this->message->order_id,
            'sender_id' => $this->message->sender_id,
            'message' => $this->message->message,
            'is_read' => $this->message->is_read,
            'created_at' => $this->message->created_at,
            'sender' => $this->message->sender,
        ];
    }
}
