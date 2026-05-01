<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use App\Models\OrderAdditionRequest;

class Order extends Model
{
    protected $primaryKey = 'order_id';

    public function getRouteKeyName()
    {
        return 'order_id';
    }

    protected $fillable = [
        'user_id',
        'driver_id',
        'event_address',
        'event_latitude',
        'event_longitude',
        'location_notes',
        'event_date',
        'status_id',
        'final_price',
        'order_date',
        'people',
        'notes',
        'started_delivery_at',
        'delivered_at',
        'delivery_notes',
        'delivery_proof_image',
    ];

    protected $casts = [
        'event_date' => 'date',
        'order_date' => 'datetime',
        'started_delivery_at' => 'datetime',
        'delivered_at' => 'datetime',
        'final_price' => 'decimal:2',
    ];

    public function user()
    {
        return $this->belongsTo(User::class, 'user_id');
    }

    public function driver()
    {
        return $this->belongsTo(User::class, 'driver_id');
    }

    public function status()
    {
        return $this->belongsTo(OrderStatus::class, 'status_id');
    }

    public function items()
    {
        return $this->hasMany(OrderItem::class, 'order_id');
    }

    public function additions()
    {
        return $this->hasMany(OrderAdditionRequest::class, 'order_id', 'order_id');
    }

    public function review()
    {
        return $this->hasOne(Review::class, 'order_id');
    }

    public function messages()
    {
        return $this->hasMany(OrderMessage::class, 'order_id');
    }
}
