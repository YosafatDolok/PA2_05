<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\SoftDeletes;

class OrderMessage extends Model
{
    use SoftDeletes;

    protected $primaryKey = 'message_id';

    protected $fillable = [
        'order_id',
        'sender_id',
        'message',
        'is_read',
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
