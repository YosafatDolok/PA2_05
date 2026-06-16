<?php

use Illuminate\Support\Facades\Route;
use App\Http\Controllers\AdminAuthController;
use App\Http\Controllers\Admin\MenuController;
use App\Http\Controllers\Admin\OrderAdditionController;
use App\Http\Controllers\Admin\MenuCategoryController;
use App\Http\Controllers\Admin\GalleryController;
use App\Http\Controllers\Admin\DashboardController;
use App\Http\Controllers\Admin\ProfileController;
use App\Http\Controllers\Admin\OrderController;
use App\Http\Controllers\Admin\AdminPaymentController;
use App\Http\Controllers\Admin\DriverController;
use App\Http\Controllers\Admin\NotificationController;

Route::redirect('/', '/login');

Route::get('/login', [AdminAuthController::class, 'showLogin'])->name('login');
Route::post('/login', [AdminAuthController::class, 'login']);
Route::post('/logout', [AdminAuthController::class, 'logout'])->middleware('auth')->name('logout');

// Driver Invitation Routes
use App\Http\Controllers\Auth\DriverInviteController;
Route::get('/driver/invite/{token}', [DriverInviteController::class, 'showSetPasswordForm'])->name('driver.invite.set-password');
Route::get('/driver/invite-success', [DriverInviteController::class, 'success'])->name('driver.invite.success');
Route::post('/driver/invite/{token}', [DriverInviteController::class, 'setPassword'])->name('driver.invite.setPassword');

use App\Http\Controllers\Admin\ReviewController;

Route::middleware(['auth', 'role:admin'])->group(function () {
    Route::get('/admin/dashboard', [DashboardController::class, 'index'])->name('admin.dashboard');
    
    Route::prefix('admin')->group(function () {
        Route::get('menus/trashed', [MenuController::class, 'trashed'])->name('menus.trashed');
        Route::post('menus/{id}/restore', [MenuController::class, 'restore'])->name('menus.restore');
        
        Route::resource('menus', MenuController::class);
        Route::resource('categories', MenuCategoryController::class);
        Route::resource('galleries', GalleryController::class);
        Route::get('/profile', [ProfileController::class, 'edit'])->name('profile.edit');
        Route::put('/profile', [ProfileController::class, 'update'])->name('profile.update');
        Route::post('/profile/confirm', [ProfileController::class, 'confirmUpdate'])->name('profile.confirm');
        
        Route::get('/orders', [OrderController::class, 'index'])->name('orders.index');

        Route::get('/orders/export', [OrderController::class, 'export'])->name('orders.export');
        Route::get('/messages', [OrderController::class, 'messages'])->name('admin.messages');
        Route::get('/orders/{id}', [OrderController::class, 'show'])->name('orders.show');
        Route::get('/orders/{id}/invoice', [OrderController::class, 'exportInvoice'])->name('orders.invoice');
        Route::get('/orders/{id}/chat', [OrderController::class, 'chat'])->name('orders.chat');
        Route::patch('/orders/{id}/status', [OrderController::class, 'updateStatus'])->name('orders.updateStatus');
        Route::post('/orders/{id}/item-prices', [OrderController::class, 'updateItemPrices'])->name('orders.updateItemPrices');
        Route::post('/orders/{id}/assign-driver', [OrderController::class, 'assignDriver'])->name('orders.assignDriver');
        Route::post('/orders/{id}/cancel-request', [App\Http\Controllers\Admin\OrderController::class, 'handleCancelRequest'])->name('orders.cancel-request');
        Route::get('/payments', [AdminPaymentController::class, 'index'])->name('admin.payments.index');

        Route::get('/additions', [OrderAdditionController::class, 'index'])->name('admin.additions.index');
        Route::patch('/additions/{id}', [OrderAdditionController::class, 'update'])->name('admin.additions.update');
        Route::post('/additions/{id}/approve', [OrderAdditionController::class, 'approve'])->name('additions.approve');
        Route::post('/additions/{id}/save-prices', [OrderAdditionController::class, 'savePrices'])->name('additions.save-prices');
        Route::post('/additions/{id}/reject', [OrderAdditionController::class, 'reject'])->name('additions.reject');
        
        // Review Routes
        Route::get('/reviews', [ReviewController::class, 'index'])->name('admin.reviews.index');
        Route::patch('/reviews/{id}/toggle', [ReviewController::class, 'toggleVisibility'])->name('admin.reviews.toggle');

        Route::get('/global-search', [DashboardController::class, 'globalSearch'])->name('admin.global-search');
        Route::get('/notifications', [NotificationController::class, 'index'])->name('admin.notifications.index');
        Route::post('/notifications/mark-read', [NotificationController::class, 'markAllAsRead'])->name('admin.notifications.markAllRead');

        // Logistics Dashboard
        Route::get('/logistics', [\App\Http\Controllers\Admin\LogisticsController::class, 'index'])->name('admin.logistics.index');
        Route::resource('drivers', DriverController::class);
        Route::post('drivers/{driver}/resend', [DriverController::class, 'resendInvitation'])->name('drivers.resend')->middleware('throttle:6,1');
        Route::post('drivers/{driver}/reset-link', [DriverController::class, 'sendResetLink'])->name('drivers.reset-link')->middleware('throttle:6,1');
    });
});