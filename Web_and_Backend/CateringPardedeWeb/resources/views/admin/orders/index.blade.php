@extends('layouts.app', [
    'page' => __('Daftar Pesanan'),
    'pageSlug' => 'orders'
])

@section('content')
    <div class="d-flex justify-content-between align-items-center mb-5">
        <div>
            <h2 class="m-0 font-weight-bold">Manajemen Pesanan</h2>
            <p class="text-muted small uppercase letter-spacing-1 mb-0">Lacak dan kelola pesanan katering pelanggan</p>
        </div>
        <div class="d-flex align-items-center" style="gap: 15px;">
            <div class="filter-group">
                <form action="{{ route('orders.index') }}" method="GET" id="filter-form" class="m-0">
                    <select name="status" class="form-control bg-dark border-secondary text-white font-weight-bold" onchange="this.form.submit()">
                        <option value="">Semua Status</option>
                        @foreach($statuses as $status)
                            <option value="{{ $status->status_id }}" {{ request('status') == $status->status_id ? 'selected' : '' }}>
                                {{ strtoupper($status->status_name) }}
                            </option>
                        @endforeach
                        <option value="unpaid_delivery" {{ request('status') == 'unpaid_delivery' ? 'selected' : '' }}>
                            TERKIRIM (BELUM DIBAYAR)
                        </option>
                    </select>
                </form>
            </div>
            <a href="{{ route('orders.export', ['status' => request('status')]) }}" class="btn btn-outline-success border-2 font-weight-bold">
                <i class="fas fa-file-excel mr-2"></i> EKSPOR EXCEL
            </a>
        </div>
    </div>

    <div class="row">
        <div class="col-12">
            <div class="card aura-card border-0 shadow-lg">
                <div class="table-responsive">
                    <table class="table align-items-center mb-0">
                        <thead>
                            <tr>
                                <th>ID PESANAN</th>
                                <th>PELANGGAN</th>
                                <th>MENU</th>
                                <th>TANGGAL ACARA</th>
                                <th>TOTAL HARGA</th>
                                <th>STATUS</th>
                                <th class="text-center">AKSI</th>
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
                                        <span class="badge bg-secondary-light extra-small mb-1 d-inline-block">{{ $item->menu->name ?? 'Unknown Item' }}</span>
                                    @endforeach
                                </td>
                                <td>
                                    <div class="text-white small">{{ $order->event_date->format('d M Y') }}</div>
                                    <div class="text-muted extra-small">{{ $order->people }} People</div>
                                </td>
                                <td>
                                    @if($order->final_price)
                                        <span class="text-secondary font-weight-bold">Rp {{ number_format($order->final_price, 0, ',', '.') }}</span>
                                        @if($order->status_id == 4 && $order->remaining_balance > 0)
                                            <br>
                                            <span class="badge bg-danger mt-1 animate-pulse" style="font-size: 10px;">
                                                UNPAID: Rp {{ number_format($order->remaining_balance, 0, ',', '.') }}
                                            </span>
                                        @endif
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
