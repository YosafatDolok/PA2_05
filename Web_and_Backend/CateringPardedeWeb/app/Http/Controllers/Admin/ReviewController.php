<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\Review;
use Illuminate\Http\Request;

class ReviewController extends Controller
{
    /**
     * Tampilkan daftar ulasan
     */
    public function index()
    {
        $reviews = Review::with(['user', 'order'])
            ->latest()
            ->paginate(10);

        return view('admin.reviews.index', compact('reviews'));
    }

    /**
     * Ubah status visibilitas ulasan
     */
    public function toggleVisibility($id)
    {
        $review = Review::findOrFail($id);
        $review->is_visible = !$review->is_visible;
        $review->save();

        return back()->with('status', 'Visibility updated successfully!');
    }
}
