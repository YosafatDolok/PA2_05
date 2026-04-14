<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Gallery extends Model
{
    protected $fillable = [
        'user_id',
        'image',
        'description'
    ];

    public function user()
    {
        return $this->belongsTo(User::class);
    }
}
