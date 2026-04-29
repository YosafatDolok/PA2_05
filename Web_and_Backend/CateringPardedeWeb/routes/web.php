<?php

use Illuminate\Support\Facades\Route;
use App\Http\Controllers\AdminAuthController;
use App\Http\Controllers\Admin\MenuController;
use App\Http\Controllers\Admin\MenuCategoryController;
use App\Http\Controllers\Admin\GalleryController;
use App\Http\Controllers\Admin\DashboardController;
use App\Http\Controllers\Admin\ProfileController;
use App\Http\Controllers\Admin\OrderController;

use App\Http\Controllers\Admin\PasswordResetController as AdminPasswordResetController;

Route::redirect('/', '/login');

Route::get('/login', [AdminAuthController::class, 'showLogin'])->name('login');
Route::post('/login', [AdminAuthController::class, 'login']);
Route::post('/logout', [AdminAuthController::class, 'logout'])->middleware('auth')->name('logout');

// Password Reset Routes (Web)
Route::get('/password/reset', [AdminPasswordResetController::class, 'showLinkRequestForm'])->name('password.request');
Route::post('/password/email', [AdminPasswordResetController::class, 'sendResetOtp'])->name('admin.password.email');
Route::get('/password/reset/verify', [AdminPasswordResetController::class, 'showResetForm'])->name('admin.password.reset');
Route::post('/password/reset', [AdminPasswordResetController::class, 'reset'])->name('admin.password.update');

Route::middleware(['auth', 'role:admin'])->group(function () {
    Route::get('/admin/dashboard', [DashboardController::class, 'index'])->name('admin.dashboard');
    
    Route::prefix('admin')->group(function () {
        Route::resource('menus', MenuController::class);
        Route::resource('categories', MenuCategoryController::class);
        Route::resource('galleries', GalleryController::class);
        Route::get('/profile', [ProfileController::class, 'edit'])->name('profile.edit');
        Route::put('/profile', [ProfileController::class, 'update'])->name('profile.update');
        
        Route::get('/orders', [OrderController::class, 'index'])->name('orders.index');
        Route::get('/orders/{id}', [OrderController::class, 'show'])->name('orders.show');
        Route::patch('/orders/{id}/status', [OrderController::class, 'updateStatus'])->name('orders.updateStatus');
    });
});