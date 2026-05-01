<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class OrderMessage extends Model
{
    protected $primaryKey = 'message_id';

    protected $fillable = [
        'order_id',
        'sender_id',
        'message',
        'is_read',
        'type',
        'proposed_price',
        'proposal_status',
    ];

    protected $casts = [
        'is_read' => 'boolean',
    ];

    public function order()
    {
        return $this->belongsTo(Order::class, 'order_id');
    }

    public function sender()
    {
        return $this->belongsTo(User::class, 'sender_id');
    }
}
