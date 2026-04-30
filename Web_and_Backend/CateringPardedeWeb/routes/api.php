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
    
    Route::post('/logout', [AuthController::class, 'logout']);

    Route::get('/orders', [OrderController::class, 'index']);
    Route::post('/orders', [OrderController::class, 'store']);
    Route::get('/orders/{id}', [OrderController::class, 'show']);
    Route::post('/orders/{id}/cancel', [OrderController::class, 'cancel']);
    Route::post('/orders/{id}/review', [ReviewController::class, 'store']);
    
    // Order Additions
    Route::post('/orders/{id}/additions', [OrderAdditionController::class, 'store']);
    Route::get('/orders/{id}/additions', [OrderAdditionController::class, 'index']);
    Route::delete('/orders/additions/{id}', [OrderAdditionController::class, 'destroy']);
    
    Route::get('/notifications', [NotificationController::class, 'index']);
    Route::get('/notifications/unread-count', [NotificationController::class, 'unreadCount']);
    Route::patch('/notifications/{id}/read', [NotificationController::class, 'markAsRead']);
    
    Route::get('/admin/dashboard', function () {
        return response()->json(['message' => 'Selamat Datang, Admin']);
    });
});