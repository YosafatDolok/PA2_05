<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class OrderAdditionItem extends Model
{
    use HasFactory;

    protected $fillable = ['request_id', 'menu_id', 'final_price'];

    public function request()
    {
        return $this->belongsTo(OrderAdditionRequest::class, 'request_id');
    }

    public function menu()
    {
        return $this->belongsTo(Menu::class, 'menu_id', 'menu_id');
    }
}
