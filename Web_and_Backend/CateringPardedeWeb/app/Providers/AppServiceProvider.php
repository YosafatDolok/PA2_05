<?php

namespace App\Providers;

use Illuminate\Support\ServiceProvider;

class AppServiceProvider extends ServiceProvider
{
    /**
     * Register any application services.
     */
    public function register(): void
    {
        //
    }

    /**
     * Bootstrap any application services.
     */
    public function boot(): void
    {
        \Illuminate\Support\Facades\View::composer('layouts.navbars.navs.auth', function ($view) {
            if (auth()->check()) {
                $notifications = \App\Models\Notification::where('user_id', auth()->id())
                    ->orderBy('created_at', 'desc')
                    ->take(5)
                    ->get();
                $unreadCount = \App\Models\Notification::where('user_id', auth()->id())
                    ->where('is_read', false)
                    ->count();
                $view->with(compact('notifications', 'unreadCount'));
            }
        });

        \Illuminate\Support\Facades\View::composer('layouts.navbars.sidebar', function ($view) {
            if (auth()->check()) {
                $pendingOrdersCount = \App\Models\Order::where('status_id', 1)->count();
                $pendingAdditionsCount = \App\Models\OrderAdditionRequest::where('status_id', 1)->count();
                
                // Fix: Count unique orders with unread messages instead of raw message count
                $unreadMessagesTotalCount = \App\Models\Order::whereHas('messages', function($query) {
                    $query->where('is_read', false)
                          ->where('sender_id', '!=', auth()->id());
                })->count();
                
                $view->with(compact('pendingOrdersCount', 'pendingAdditionsCount', 'unreadMessagesTotalCount'));
            }
        });
    }
}
