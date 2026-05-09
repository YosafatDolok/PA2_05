<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class ProcessedPayment extends Model
{
    protected $fillable = [
        'order_id',
        'external_id',
        'amount'
    ];
}
