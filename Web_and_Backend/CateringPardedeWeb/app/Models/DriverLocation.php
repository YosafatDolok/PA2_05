<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class DriverLocation extends Model
{
    public $timestamps = false; // We handle updated_at manually in migration via useCurrentOnUpdate

    protected $fillable = [
        'user_id',
        'latitude',
        'longitude',
        'updated_at'
    ];

    public function user()
    {
        return $this->belongsTo(User::class, 'user_id', 'user_id');
    }
}
