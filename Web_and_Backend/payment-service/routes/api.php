<?php

use Illuminate\Support\Facades\Route;
use App\Http\Controllers\PaymentController;

Route::post('/payments', [PaymentController::class, 'store']);
Route::post('/payments/{id}/pay', [PaymentController::class, 'pay']);
Route::patch('/orders/{id}/status', [OrderController::class, 'updateStatus']);
Route::get('/payments/order/{orderId}', [PaymentController::class, 'getByOrder']);
Route::patch('/payments/{id}/pay', [PaymentController::class, 'pay']);
Route::post('/payments/{id}/midtrans', [PaymentController::class, 'createTransaction']);
