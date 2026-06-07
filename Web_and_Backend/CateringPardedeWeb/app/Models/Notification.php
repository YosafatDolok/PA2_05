<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Notification extends Model
{
    use HasFactory;

    protected static function booted()
    {
        static::created(function ($notification) {
            event(new \App\Events\NotificationSent($notification));
        });
    }


    protected $primaryKey = 'notification_id';

    protected $fillable = [
        'user_id',
        'type',
        'title',
        'message',
        'related_id',
        'is_read',
    ];

    protected $casts = [
        'is_read' => 'boolean',
    ];

    public function user()
    {
        return $this->belongsTo(User::class, 'user_id', 'user_id');
    }
}
