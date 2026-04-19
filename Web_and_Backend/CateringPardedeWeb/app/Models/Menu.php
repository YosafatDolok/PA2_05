<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Menu extends Model
{
    protected $fillable = [
        'name',
        'description',
        'image',
        'user_id',
        'category_id',
        'available'
    ];

    public function category()
    {
        return $this->belongsTo(MenuCategory::class, 'category_id');
    }

    public function user()
    {
        return $this->belongsTo(User::class, 'user_id');
    }

    protected $primaryKey = 'menu_id';
}
