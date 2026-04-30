@extends('layouts.app', ['page' => __('Order Additions'), 'pageSlug' => 'additions'])

@section('content')
<div class="row">
    <div class="col-md-12">
        <div class="card card-neo">
            <div class="card-header">
                <h4 class="card-title">Permintaan Tambahan Menu</h4>
                <p class="category">Review and price additional menu requests from customers.</p>
            </div>
            <div class="card-body">
                @if (session('success'))
                    <div class="alert alert-success">
                        {{ session('success') }}
                    </div>
                @endif

                <div class="table-responsive">
                    <table class="table">
                        <thead class="text-primary">
                            <tr>
                                <th>Order ID</th>
                                <th>Customer</th>
                                <th>Menus</th>
                                <th>Status</th>
                                <th>Actions</th>
                            </tr>
                        </thead>
                        <tbody>
                            @foreach ($requests as $req)
                                <tr>
                                    <td>#ORD-{{ str_pad($req->order_id, 5, '0', STR_PAD_LEFT) }}</td>
                                    <td>{{ $req->order->user->name }}</td>
                                    <td>
                                        <ul class="list-unstyled mb-0">
                                            @foreach ($req->items as $item)
                                                <li><i class="fas fa-utensils mr-2 text-danger"></i> {{ $item->menu->name }}</li>
                                            @endforeach
                                        </ul>
                                    </td>
                                    <td>
                                        <span class="badge badge-{{ $req->status_id == 1 ? 'warning' : ($req->status_id == 2 ? 'success' : 'danger') }}">
                                            {{ $req->status->name }}
                                        </span>
                                    </td>
                                    <td>
                                        @if ($req->status_id == 1)
                                            <a href="{{ route('orders.show', $req->order_id) }}#additions-section" class="btn btn-sm btn-aura">
                                                <i class="fas fa-eye"></i> Review
                                            </a>
                                        @else
                                            <span class="text-muted small">Processed</span>
                                        @endif
                                    </td>
                                </tr>
                            @endforeach
                        </tbody>
                    </table>
                </div>
                {{ $requests->links() }}
            </div>
        </div>
    </div>
</div>
@endsection
