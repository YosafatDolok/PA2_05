<?php

namespace App\Events;

use App\Models\DeliveryMessage;
use Illuminate\Broadcasting\InteractsWithSockets;
use Illuminate\Broadcasting\PrivateChannel;
use Illuminate\Contracts\Broadcasting\ShouldBroadcastNow;
use Illuminate\Foundation\Events\Dispatchable;
use Illuminate\Queue\SerializesModels;

class DeliveryMessageDeleted implements ShouldBroadcastNow
{
    use Dispatchable, InteractsWithSockets, SerializesModels;

    public function __construct(public readonly DeliveryMessage $message) {}

    public function broadcastAs(): string
    {
        return 'delivery.message.deleted';
    }

    public function broadcastOn(): array
    {
        return [
            new PrivateChannel('delivery.order.' . $this->message->order_id),
        ];
    }

    public function broadcastWith(): array
    {
        return [
            'message_id' => $this->message->message_id,
            'order_id'   => $this->message->order_id,
        ];
    }
}
