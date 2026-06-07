<?php

use Illuminate\Support\Facades\Broadcast;

Broadcast::channel('App.Models.User.{id}', function ($user, $id) {
    return (int) $user->user_id === (int) $id;
});

Broadcast::channel('order.{orderId}', function ($user, $orderId) {
    $order = \App\Models\Order::find($orderId);
    if (!$order) return false;
    
    // Admin (role_id 1) or the owner of the order can join
    return $user->role_id === 1 || $order->user_id === $user->user_id;
});

Broadcast::channel('delivery.order.{orderId}', function ($user, $orderId) {
    $order = \App\Models\Order::find($orderId);
    if (!$order) return false;
    
    // Customer (user_id) or Driver (driver_id) can join
    return $order->user_id === $user->user_id || $order->driver_id === $user->user_id;
});
