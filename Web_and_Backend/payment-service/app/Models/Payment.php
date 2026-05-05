<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Payment extends Model
{
    protected $fillable = [
        'order_id',
        'midtrans_id',
        'snap_token',
        'amount',
        'payment_method',
        'payment_type',
        'status',
        'external_id',
        'transaction_time'
    ];
}
