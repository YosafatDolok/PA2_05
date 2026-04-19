<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class MenuCategory extends Model
{
    protected $fillable = [
        'name'
    ];

    public function menus()
    {
        return $this->hasMany(Menu::class, 'category_id');
    }

    protected $primaryKey = 'category_id';
}
