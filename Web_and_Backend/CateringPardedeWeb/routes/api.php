<?php

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;
use App\Http\Controllers\AuthController;
use App\Http\Controllers\Admin\MenuController;
use App\Http\Controllers\Admin\ProfileController;
use App\Http\Controllers\Admin\GalleryController;
use App\Http\Controllers\Admin\MenuCategoryController;
use App\Http\Controllers\Api\OrderController;
use App\Http\Controllers\Api\NotificationController;
use App\Http\Controllers\Api\PasswordResetController;
use App\Http\Controllers\Api\OrderAdditionController;
use App\Http\Controllers\Api\ReviewController;
use App\Http\Controllers\Api\OrderMessageController;
use App\Http\Controllers\Api\AdminDashboardController;
use App\Http\Controllers\Api\CheckoutTokenController;


Route::post('/register/otp', [AuthController::class, 'requestRegistrationOtp']);
Route::post('/register/resend-otp', [AuthController::class, 'resendRegistrationOtp']);
Route::post('/register', [AuthController::class, 'register']);
Route::post('/login', [AuthController::class, 'login']);

// Password Reset Routes
Route::post('/password/forgot', [PasswordResetController::class, 'sendOtp']);
Route::post('/password/verify', [PasswordResetController::class, 'verifyOtp']);
Route::post('/password/reset', [PasswordResetController::class, 'resetPassword']);

Route::get('/menus', [MenuController::class, 'apiIndex']);
Route::get('/menus/{id}', [MenuController::class, 'apiShow']);

Route::get('/categories', [MenuCategoryController::class, 'apiIndex']);

Route::get('/galleries', [GalleryController::class, 'apiIndex']);
Route::get('/galleries/{id}', [GalleryController::class, 'apiShow']);

Route::get('/reviews', [ReviewController::class, 'index']);

Route::middleware('auth:sanctum')->group(function () {
    Route::get('/user', [AuthController::class, 'user']);
    Route::post('/user/update', [ProfileController::class, 'update']); 
    Route::post('/user/update/verify-otp', [ProfileController::class, 'verifyProfileOtp']); 
    Route::post('/user/update/resend-otp', [ProfileController::class, 'resendProfileOtp']); 
    Route::post('/user/fcm-token', [ProfileController::class, 'updateFcmToken']); 
    Route::post('/user/password', [ProfileController::class, 'updatePassword']); 
    Route::delete('/user', [ProfileController::class, 'destroy']); 
    
    Route::post('/logout', [AuthController::class, 'logout']);

    // Pusher/Reverb Auth for API
    Route::post('/broadcasting/auth', function (\Illuminate\Http\Request $request) {
        return \Illuminate\Support\Facades\Broadcast::auth($request);
    });

    Route::get('/orders', [OrderController::class, 'index']);
    Route::post('/orders', [OrderController::class, 'store']);
    Route::get('/orders/{id}', [OrderController::class, 'show']);
    Route::get('/orders/{id}/checkout-token', [CheckoutTokenController::class, 'generateToken']);
    Route::post('/orders/{id}/cancel', [OrderController::class, 'cancel']);
    Route::post('/orders/{id}/request-cancel', [OrderController::class, 'requestCancel']);
    Route::post('/orders/{id}/review', [ReviewController::class, 'store']);
    Route::patch('/orders/{id}/review', [ReviewController::class, 'update']);
    Route::delete('/orders/{id}/review', [ReviewController::class, 'destroy']);

    // Order Messaging
    Route::get('/messages/unread-count', [OrderMessageController::class, 'unreadCount']);
    Route::get('/orders/{order}/messages', [OrderMessageController::class, 'index']);
    Route::post('/orders/{order}/messages', [OrderMessageController::class, 'store']);
    Route::post('/orders/{order}/messages/read', [OrderMessageController::class, 'markAsRead']);


    // Delivery Messaging
    Route::get('/orders/{order}/delivery-messages', [\App\Http\Controllers\Api\DeliveryChatController::class, 'index']);
    Route::post('/orders/{order}/delivery-messages', [\App\Http\Controllers\Api\DeliveryChatController::class, 'store']);
    Route::post('/orders/{order}/delivery-messages/read', [\App\Http\Controllers\Api\DeliveryChatController::class, 'markAsRead']);
    
    // Admin Inbox
    Route::get('/admin/inbox', [\App\Http\Controllers\Api\AdminChatController::class, 'inbox']);
    
    // Order Additions
    Route::post('/orders/{id}/additions', [OrderAdditionController::class, 'store']);
    Route::get('/orders/{id}/additions', [OrderAdditionController::class, 'index']);
    Route::delete('/orders/additions/{id}', [OrderAdditionController::class, 'destroy']);
    
    Route::get('/notifications', [NotificationController::class, 'index']);
    Route::get('/notifications/unread-count', [NotificationController::class, 'unreadCount']);
    Route::patch('/notifications/{id}/read', [NotificationController::class, 'markAsRead']);
    
    Route::get('/admin/stats', [AdminDashboardController::class, 'getStats']);

    // Driver Logistics
    Route::prefix('driver')->group(function () {
        Route::get('/orders', [\App\Http\Controllers\Api\DriverController::class, 'myOrders']);
        Route::get('/inbox', [\App\Http\Controllers\Api\DriverController::class, 'inbox']);
        Route::post('/orders/{id}/status', [\App\Http\Controllers\Api\DriverController::class, 'updateStatus']);
    });
});


Route::middleware('internal.service')->group(function () {
    Route::patch('/orders/{id}/status', [OrderController::class, 'updateStatus']);
    Route::get('/orders/{id}/billing', [OrderController::class, 'getBillingDetails']);
    Route::post('/orders/{id}/payments', [OrderController::class, 'receivePaymentNotification']);
});
