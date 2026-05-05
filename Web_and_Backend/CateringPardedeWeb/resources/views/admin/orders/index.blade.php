@extends('layouts.app', [
    'page' => __('Order List'),
    'pageSlug' => 'orders'
])

@section('content')
    <div class="d-flex justify-content-between align-items-center mb-5">
        <div>
            <h2 class="m-0 font-weight-bold">Order Management</h2>
            <p class="text-muted small uppercase letter-spacing-1 mb-0">Track and manage customer catering requests</p>
        </div>
        <a href="{{ route('orders.export') }}" class="btn btn-outline-success border-2 font-weight-bold">
            <i class="fas fa-file-excel mr-2"></i> EXPORT EXCEL
        </a>
    </div>

    <div class="row">
        <div class="col-12">
            <div class="card aura-card border-0 shadow-lg">
                <div class="table-responsive">
                    <table class="table align-items-center mb-0">
                        <thead>
                            <tr>
                                <th>ORDER ID</th>
                                <th>CUSTOMER</th>
                                <th>MENUS</th>
                                <th>EVENT DATE</th>
                                <th>TOTAL PRICE</th>
                                <th>STATUS</th>
                                <th class="text-center">ACTIONS</th>
                            </tr>
                        </thead>
                        <tbody>
                            @foreach($orders as $order)
                            <tr>
                                <td>
                                    <span class="font-weight-bold text-white">#ORD-{{ str_pad($order->order_id, 5, '0', STR_PAD_LEFT) }}</span>
                                    @if($order->unread_messages_count > 0)
                                        <span class="badge bg-crimson pulse-mini ml-2" title="New messages">
                                            <i class="fas fa-comment"></i> {{ $order->unread_messages_count }}
                                        </span>
                                    @endif
                                </td>
                                <td>
                                    <div class="mb-0 font-weight-bold text-whitefs-6">{{ $order->user->name }}</div>
                                    <div class="text-muted extra-small mt-1">{{ $order->user->email }}</div>
                                </td>
                                <td>
                                    @foreach($order->items as $item)
                                        <span class="badge bg-secondary-light extra-small mb-1 d-inline-block">{{ $item->menu->name }}</span>
                                    @endforeach
                                </td>
                                <td>
                                    <div class="text-white small">{{ $order->event_date->format('d M Y') }}</div>
                                    <div class="text-muted extra-small">{{ $order->people }} People</div>
                                </td>
                                <td>
                                    @if($order->final_price)
                                        <span class="text-secondary font-weight-bold">Rp {{ number_format($order->final_price, 0, ',', '.') }}</span>
                                    @else
                                        <span class="badge bg-warning-light small">MENUNGGU HARGA</span>
                                    @endif
                                </td>
                                <td>
                                    @php
                                        $statusClass = 'badge ';
                                        switch($order->status->status_name) {
                                            case 'Pending': $statusClass .= 'bg-warning-light'; break;
                                            case 'Preparing': $statusClass .= 'bg-info-light'; break;
                                            case 'Out for Delivery': $statusClass .= 'bg-primary-light'; break;
                                            case 'Delivered': $statusClass .= 'bg-success-light'; break;
                                            default: $statusClass .= 'bg-secondary-light';
                                        }
                                    @endphp
                                    <span class="{{ $statusClass }}">{{ strtoupper($order->status->status_name) }}</span>
                                </td>
                                <td class="text-center">
                                    <a href="{{ route('orders.show', $order->order_id) }}" class="btn btn-sm btn-icon btn-secondary rounded-circle">
                                        <i class="fas fa-eye"></i>
                                    </a>
                                </td>
                            </tr>
                            @endforeach
                        </tbody>
                    </table>
                </div>
            </div>
        </div>
    </div>
@endsection
