<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class OrderAdditionRequest extends Model
{
    use HasFactory;

    protected $fillable = ['order_id', 'status_id', 'notes'];

    public function order()
    {
        return $this->belongsTo(Order::class, 'order_id', 'order_id');
    }

    public function status()
    {
        return $this->belongsTo(OrderStatus::class, 'status_id', 'status_id');
    }

    public function items()
    {
        return $this->hasMany(OrderAdditionItem::class, 'request_id');
    }
}
