<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class DeliveryInboxResource extends JsonResource
{
    /**
     * Transform the resource into an array.
     *
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        return [
            'order_id' => $this->order_id,
            'user' => [
                'name' => $this->user->name ?? 'Pelanggan',
                'profile_picture' => $this->user->profile_picture,
            ],
            'latest_message' => [
                'message' => $this->latestDeliveryMessage->message ?? '...',
                'created_at' => $this->latestDeliveryMessage?->created_at?->toIso8601String() ?? $this->updated_at->toIso8601String(),
            ],
            'unread_count' => (int) $this->unread_count,
        ];
    }
}
