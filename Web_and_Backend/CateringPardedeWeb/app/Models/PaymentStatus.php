<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class PaymentStatus extends Model
{
    protected $table = 'payment_statuses';
    protected $primaryKey = 'pstatus_id';
    
    protected $fillable = ['pstatus_name'];
}
