<?php

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;
use App\Http\Controllers\AuthController;
use App\Http\Controllers\Admin\MenuController;
use App\Http\Controllers\Admin\ProfileController;
use App\Http\Controllers\Admin\GalleryController;
use App\Http\Controllers\Admin\MenuCategoryController;
use App\Http\Controllers\Api\OrderController;

Route::post('/register', [AuthController::class, 'register']);
Route::post('/login', [AuthController::class, 'login']);

Route::get('/menus', [MenuController::class, 'apiIndex']);
Route::get('/menus/{id}', [MenuController::class, 'apiShow']);

Route::get('/categories', [MenuCategoryController::class, 'apiIndex']);

Route::get('/galleries', [GalleryController::class, 'apiIndex']);
Route::get('/galleries/{id}', [GalleryController::class, 'apiShow']);

Route::get('/galleries', [GalleryController::class, 'apiIndex']);
Route::get('/galleries/{id}', [GalleryController::class, 'apiShow']);

Route::middleware('auth:sanctum')->group(function () {
    Route::get('/user', [AuthController::class, 'user']);
    Route::post('/user/update', [ProfileController::class, 'update']); 
    
    Route::post('/logout', [AuthController::class, 'logout']);

    Route::get('/orders', [OrderController::class, 'index']);
    Route::post('/orders', [OrderController::class, 'store']);
    Route::get('/orders/{id}', [OrderController::class, 'show']);
    Route::post('/orders/{id}/cancel', [OrderController::class, 'cancel']);
    
    Route::get('/admin/dashboard', function () {
        return response()->json(['message' => 'Selamat Datang, Admin']);
    });
});