<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Order;
use App\Models\Review;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Validator;

class ReviewController extends Controller
{
    /**
     * Store a new review for an order.
     */
    public function store(Request $request, $orderId)
    {
        $validator = Validator::make($request->all(), [
            'rating' => 'required|integer|min:1|max:5',
            'comment' => 'nullable|string|max:1000',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'message' => 'Validasi gagal',
                'errors' => $validator->errors()
            ], 422);
        }

        $order = Order::where('order_id', $orderId)
            ->where('user_id', auth()->id())
            ->first();

        if (!$order) {
            return response()->json([
                'success' => false,
                'message' => 'Pesanan tidak ditemukan'
            ], 404);
        }

        // Only allow reviews for completed orders
        // Note: Assuming status_id for 'Selesai' is 4 based on typical flows, 
        // but we should check the actual status name if possible.
        // For now, let's look at the status relationship.
        if ($order->status->status_name !== 'Selesai') {
            return response()->json([
                'success' => false,
                'message' => 'Anda hanya dapat memberikan ulasan untuk pesanan yang sudah selesai'
            ], 400);
        }

        // Check if already reviewed
        if ($order->review) {
            return response()->json([
                'success' => false,
                'message' => 'Anda sudah memberikan ulasan untuk pesanan ini'
            ], 400);
        }

        $review = Review::create([
            'order_id' => $order->order_id,
            'user_id' => auth()->id(),
            'rating' => $request->rating,
            'comment' => $request->comment,
            'is_visible' => true
        ]);

        return response()->json([
            'success' => true,
            'message' => 'Terima kasih atas ulasan Anda!',
            'data' => $review
        ], 201);
    }

    /**
     * Get latest public reviews.
     */
    public function index()
    {
        $reviews = Review::with(['user:user_id,name'])
            ->where('is_visible', true)
            ->latest()
            ->take(10)
            ->get();

        return response()->json([
            'success' => true,
            'data' => $reviews
        ]);
    }
}
