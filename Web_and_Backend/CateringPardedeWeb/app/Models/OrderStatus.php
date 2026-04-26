<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class OrderStatus extends Model
{
    protected $table = 'order_statuses';
    protected $primaryKey = 'status_id';
    
    protected $fillable = ['status_name'];
}
