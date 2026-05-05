<?php

use Illuminate\Support\Facades\Route;
use App\Http\Controllers\PaymentController;
use App\Http\Controllers\PaymentHistoryController;

/*
|--------------------------------------------------------------------------
| API Routes
|--------------------------------------------------------------------------
*/

// Public/Mobile Endpoints
Route::post('/payments', [PaymentController::class, 'store']);
Route::get('/payments/order/{orderId}', [PaymentController::class, 'getByOrder']);
Route::post('/payments/{id}/midtrans', [PaymentController::class, 'createTransaction']);
Route::post('/payments/callback', [PaymentController::class, 'callback']);

// Secure Internal Endpoints (Admin Bridge)
Route::middleware('internal.service')->group(function () {
    Route::get('/history', [PaymentHistoryController::class, 'index']);
    Route::get('/history/order/{id}', [PaymentHistoryController::class, 'show']);
    Route::get('/stats/summary', [\App\Http\Controllers\PaymentStatsController::class, 'getSummary']);
});