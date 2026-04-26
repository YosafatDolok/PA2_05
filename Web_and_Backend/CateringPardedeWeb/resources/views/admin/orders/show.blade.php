@extends('layouts.app', [
    'page' => __('Order Detail'),
    'pageSlug' => 'orders'
])

@section('content')
    <div class="d-flex justify-content-between align-items-center mb-5">
        <div>
            <h2 class="m-0 font-weight-bold">Order #ORD-{{ str_pad($order->order_id, 5, '0', STR_PAD_LEFT) }}</h2>
            <p class="text-muted small uppercase letter-spacing-1 mb-0">Detailed view and status management</p>
        </div>
        <a href="{{ route('orders.index') }}" class="btn btn-secondary btn-icon rounded-circle">
            <i class="fas fa-arrow-left"></i>
        </a>
    </div>

    <div class="row">
        <div class="col-md-8">
            <div class="card aura-card border-0 shadow-lg p-4 mb-4">
                <h4 class="font-weight-bold mb-4 text-secondary border-bottom border-secondary pb-2">Ordered Menus</h4>
                <div class="table-responsive">
                    <table class="table text-white mb-0">
                        <thead>
                            <tr class="text-muted extra-small uppercase">
                                <th>Menu Name</th>
                                <th class="text-right">Action</th>
                            </tr>
                        </thead>
                        <tbody>
                            @foreach($order->items as $item)
                            <tr>
                                <td class="py-3">
                                    <div class="d-flex align-items-center">
                                        <div class="menu-dot mr-3"></div>
                                        <span class="font-weight-bold">{{ $item->menu->name }}</span>
                                    </div>
                                </td>
                                <td class="text-right py-3">
                                    <a href="{{ route('menus.edit', $item->menu_id) }}" class="btn btn-link btn-sm text-secondary p-0">View Menu</a>
                                </td>
                            </tr>
                            @endforeach
                        </tbody>
                    </table>
                </div>
            </div>

            <div class="card aura-card border-0 shadow-lg p-4 mb-4">
                <h4 class="font-weight-bold mb-4 text-secondary border-bottom border-secondary pb-2">Customer & Event Info</h4>
                <div class="row mb-3">
                    <div class="col-sm-4 text-muted small uppercase">Customer Name</div>
                    <div class="col-sm-8 text-white font-weight-bold">{{ $order->user->name }}</div>
                </div>
                <div class="row mb-3">
                    <div class="col-sm-4 text-muted small uppercase">Event Address</div>
                    <div class="col-sm-8 text-white">{{ $order->event_address }}</div>
                </div>
                <div class="row mb-3">
                    <div class="col-sm-4 text-muted small uppercase">Event Date</div>
                    <div class="col-sm-8 text-white">{{ $order->event_date->format('l, d F Y') }}</div>
                </div>
                <div class="row mb-3">
                    <div class="col-sm-4 text-muted small uppercase">Capacity</div>
                    <div class="col-sm-8 text-white">{{ $order->people }} People</div>
                </div>
                <div class="row">
                    <div class="col-sm-4 text-muted small uppercase">Notes</div>
                    <div class="col-sm-8 text-white italic-placeholder">{{ $order->notes ?? 'No specific notes' }}</div>
                </div>
            </div>

            <div class="card aura-card border-0 shadow-lg p-4">
                <h4 class="font-weight-bold mb-4 text-secondary border-bottom border-secondary pb-2">Delivery Info</h4>
                <div class="row mb-3">
                    <div class="col-sm-4 text-muted small uppercase">Status</div>
                    <div class="col-sm-8">
                        <span class="badge bg-primary-light">{{ strtoupper($order->status->status_name) }}</span>
                    </div>
                </div>
                @if($order->delivered_at)
                <div class="row mb-3">
                    <div class="col-sm-4 text-muted small uppercase">Delivered At</div>
                    <div class="col-sm-8 text-white">{{ $order->delivered_at->format('d M Y, H:i') }}</div>
                </div>
                @endif
                <div class="row">
                    <div class="col-sm-4 text-muted small uppercase">Location Notes</div>
                    <div class="col-sm-8 text-white">{{ $order->location_notes ?? '-' }}</div>
                </div>
            </div>
        </div>

        <div class="col-md-4">
            <div class="card aura-card border-0 shadow-lg p-4 mb-4">
                <h4 class="font-weight-bold mb-4 text-secondary border-bottom border-secondary pb-2">Action Center</h4>
                <form action="{{ route('orders.updateStatus', $order->order_id) }}" method="POST">
                    @csrf
                    @method('PATCH')
                    
                    <div class="mb-4">
                        <label class="text-muted small uppercase mb-2 d-block">Harga Final (Rp)</label>
                        <input type="number" name="final_price" value="{{ $order->final_price ? intval($order->final_price) : '' }}" 
                               class="form-control bg-dark border-secondary text-white" 
                               placeholder="Masukkan harga total...">
                    </div>

                    <div class="mb-4">
                        <label class="text-muted small uppercase mb-2 d-block">Update Status</label>
                        <select name="status_id" class="form-control bg-dark border-secondary text-white">
                            @foreach($statuses as $status)
                                <option value="{{ $status->status_id }}" {{ $order->status_id == $status->status_id ? 'selected' : '' }}>
                                    {{ $status->status_name }}
                                </option>
                            @endforeach
                        </select>
                    </div>
                    <button type="submit" class="btn btn-primary w-100 rounded-pill">SIMPAN PERUBAHAN</button>
                </form>
            </div>

            <div class="card aura-card border-0 shadow-lg p-4">
                <h4 class="font-weight-bold mb-4 text-secondary border-bottom border-secondary pb-2">Order Summary</h4>
                <div class="d-flex justify-content-between align-items-center">
                    <span class="text-muted small uppercase">Final Price</span>
                    @if($order->final_price)
                        <h3 class="text-secondary font-weight-bold mb-0">Rp {{ number_format($order->final_price, 0, ',', '.') }}</h3>
                    @else
                        <h4 class="text-warning font-weight-bold mb-0">MENUNGGU HARGA</h4>
                    @endif
                </div>
            </div>
        </div>
    </div>
@endsection
