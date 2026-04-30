@extends('layouts.app', ['page' => 'Customer Reviews', 'pageSlug' => 'reviews'])

@section('content')
<div class="row">
    <div class="col-md-12">
        <div class="card aura-card">
            <div class="card-header d-flex justify-content-between align-items-center">
                <h4 class="card-title m-0">Customer Feedback</h4>
                <div class="text-muted small">Manage visibility of customer testimonials</div>
            </div>
            <div class="card-body">
                @if (session('status'))
                    <div class="alert bg-aura-crimson-soft text-aura-crimson border-0 animate-pulse-crimson mb-4">
                        {{ session('status') }}
                    </div>
                @endif

                <div class="table-responsive">
                    <table class="table">
                        <thead>
                            <tr>
                                <th>Order</th>
                                <th>Customer</th>
                                <th>Rating</th>
                                <th>Comment</th>
                                <th>Date</th>
                                <th>Status</th>
                                <th class="text-right">Actions</th>
                            </tr>
                        </thead>
                        <tbody>
                            @forelse($reviews as $review)
                                <tr class="{{ !$review->is_visible ? 'opacity-50' : '' }}">
                                    <td>
                                        <a href="{{ route('orders.show', $review->order_id) }}" class="text-aura-crimson font-weight-bold">
                                            ORD-{{ str_pad($review->order_id, 5, '0', STR_PAD_LEFT) }}
                                        </a>
                                    </td>
                                    <td>
                                        <div class="d-flex align-items-center">
                                            <div class="avatar-sm bg-aura-glass rounded-circle p-2 me-2">
                                                <i class="fas fa-user-circle text-muted"></i>
                                            </div>
                                            <span>{{ $review->user->name }}</span>
                                        </div>
                                    </td>
                                    <td>
                                        <div class="text-warning">
                                            @for($i = 1; $i <= 5; $i++)
                                                <i class="{{ $i <= $review->rating ? 'fas' : 'far' }} fa-star" 
                                                   style="{{ $i <= $review->rating ? 'text-shadow: 0 0 10px rgba(255,193,7,0.5);' : '' }}"></i>
                                            @endfor
                                        </div>
                                    </td>
                                    <td style="max-width: 300px;">
                                        <p class="mb-0 text-truncate" title="{{ $review->comment }}">
                                            {{ $review->comment }}
                                        </p>
                                    </td>
                                    <td class="text-muted smaller">
                                        {{ $review->created_at->format('d M Y, H:i') }}
                                    </td>
                                    <td>
                                        <span class="badge {{ $review->is_visible ? 'bg-success-light' : 'bg-secondary' }}">
                                            {{ $review->is_visible ? 'VISIBLE' : 'HIDDEN' }}
                                        </span>
                                    </td>
                                    <td class="td-actions text-right">
                                        <div class="d-flex justify-content-end gap-2">
                                            <form action="{{ route('admin.reviews.toggle', $review->review_id) }}" method="POST">
                                                @csrf
                                                @method('PATCH')
                                                <button type="submit" class="btn btn-icon btn-secondary" title="{{ $review->is_visible ? 'Hide' : 'Show' }}">
                                                    <i class="fas {{ $review->is_visible ? 'fa-eye-slash' : 'fa-eye' }}"></i>
                                                </button>
                                            </form>
                                            
                                            <form action="{{ route('admin.reviews.destroy', $review->review_id) }}" method="POST" onsubmit="return confirm('Delete this review permanently?')">
                                                @csrf
                                                @method('DELETE')
                                                <button type="submit" class="btn btn-icon btn-danger-light">
                                                    <i class="fas fa-trash"></i>
                                                </button>
                                            </form>
                                        </div>
                                    </td>
                                </tr>
                            @empty
                                <tr>
                                    <td colspan="7" class="text-center py-5 text-muted">
                                        <i class="fas fa-comment-slash fa-3x mb-3 opacity-20"></i>
                                        <p>No customer reviews yet.</p>
                                    </td>
                                </tr>
                            @endforelse
                        </tbody>
                    </table>
                </div>
                <div class="mt-4">
                    {{ $reviews->links() }}
                </div>
            </div>
        </div>
    </div>
</div>
@endsection
