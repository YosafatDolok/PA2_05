<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class ChatInboxResource extends JsonResource
{
    /**
     * Transform the resource into an array.
     *
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        $user = auth()->user();
        $isCustomer = $user && (int)$user->role_id === 2;

        return [
            'order_id' => $this->order_id,
            'user' => [
                'name' => $isCustomer ? 'Catering Admin' : ($this->user->name ?? 'Pelanggan'),
                'profile_picture' => $isCustomer ? null : $this->user->profile_picture,
            ],
            'latest_message' => [
                'message' => $this->latestMessage->message ?? '...',
                'created_at' => $this->latestMessage?->created_at?->toIso8601String() ?? $this->updated_at->toIso8601String(),
            ],
            'unread_count' => (int) $this->unread_count,
        ];
    }
}
