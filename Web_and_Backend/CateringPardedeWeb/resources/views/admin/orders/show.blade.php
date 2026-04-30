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

    @php
        $pendingAdditions = $order->additions->where('status_id', 1)->count();
    @endphp

    @if($pendingAdditions > 0)
        <div class="alert alert-crimson aura-card mb-4 border-0 shadow-lg animate-pulse" style="background: rgba(225, 48, 108, 0.1); border-left: 4px solid #e1306c !important; color: #e1306c;">
            <div class="d-flex align-items-center">
                <i class="fas fa-exclamation-circle mr-3"></i>
                <span class="font-weight-bold">PERHATIAN: Ada {{ $pendingAdditions }} permintaan menu tambahan yang perlu ditinjau!</span>
            </div>
        </div>
    @endif

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

            @if($order->additions->count() > 0)
            <div id="additions-section" class="card aura-card border-0 shadow-lg p-4 mb-4">
                <h4 class="font-weight-bold mb-4 text-secondary border-bottom border-secondary pb-2">Additional Menus (Additions)</h4>
                @foreach($order->additions as $addition)
                    <div class="addition-request mb-4 p-3 rounded" style="background: rgba(255,255,255,0.03); border-left: 3px solid {{ $addition->status_id == 1 ? '#ff9800' : ($addition->status_id == 2 ? '#4caf50' : '#f44336') }}">
                        <div class="d-flex justify-content-between align-items-start mb-3">
                            <div>
                                <span class="badge {{ $addition->status_id == 1 ? 'bg-warning' : ($addition->status_id == 2 ? 'bg-success' : 'bg-danger') }} small uppercase mb-2">
                                    {{ $addition->status->status_name }}
                                </span>
                                <p class="text-muted extra-small mb-0">Request Date: {{ $addition->created_at->format('d M Y, H:i') }}</p>
                            </div>
                            @if($addition->status_id == 2)
                                <h5 class="text-secondary font-weight-bold">Rp {{ number_format($addition->items->sum('final_price'), 0, ',', '.') }}</h5>
                            @endif
                        </div>

                        <ul class="list-unstyled mb-3">
                            @foreach($addition->items as $item)
                                <li class="text-white d-flex justify-content-between">
                                    <span>• {{ $item->menu->name }}</span>
                                    @if($addition->status_id == 2)
                                        <span class="text-muted small">Rp {{ number_format($item->final_price, 0, ',', '.') }}</span>
                                    @endif
                                </li>
                            @endforeach
                        </ul>

                        @if($addition->notes)
                            <div class="bg-dark p-2 rounded mb-3">
                                <p class="text-muted extra-small italic mb-0">"{{ $addition->notes }}"</p>
                            </div>
                        @endif

                        @if($addition->status_id == 1)
                            <form action="{{ route('additions.approve', $addition->id) }}" method="POST" class="mt-3">
                                @csrf
                                <div class="row align-items-end">
                                    @foreach($addition->items as $item)
                                        <div class="col-md-6 mb-2">
                                            <label class="extra-small text-muted mb-1">{{ $item->menu->name }} Price (Rp)</label>
                                            <input type="number" name="prices[{{ $item->id }}]" class="form-control form-control-sm bg-dark border-secondary text-white animate-pulse-crimson" placeholder="Harga per request...">
                                        </div>
                                    @endforeach
                                    <div class="col-12 mt-2">
                                        <button type="submit" class="btn btn-primary btn-sm rounded-pill px-4 font-weight-bold">APPROVE & SET PRICES</button>
                                        <button type="submit" form="reject-form-{{ $addition->id }}" class="btn btn-link btn-sm text-danger">Reject</button>
                                    </div>
                                </div>
                            </form>
                            <form id="reject-form-{{ $addition->id }}" action="{{ route('additions.reject', $addition->id) }}" method="POST" style="display: none;">
                                @csrf
                            </form>
                        @endif
                    </div>
                @endforeach
            </div>
            @endif

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
                        <input type="number" name="final_price" value="{{ old('final_price', $order->final_price ? intval($order->final_price) : '') }}" 
                               class="form-control bg-dark border-secondary text-white @error('final_price') is-invalid @enderror {{ !$order->final_price ? 'animate-pulse-crimson' : '' }}" 
                               placeholder="Masukkan harga total...">
                        @error('final_price')
                            <span class="invalid-feedback">{{ $message }}</span>
                        @enderror
                    </div>

                    <div class="mb-4">
                        <label class="text-muted small uppercase mb-2 d-block">Update Status</label>
                        <select name="status_id" class="form-control bg-dark border-secondary text-white @error('status_id') is-invalid @enderror">
                            @foreach($statuses as $status)
                                <option value="{{ $status->status_id }}" {{ old('status_id', $order->status_id) == $status->status_id ? 'selected' : '' }}>
                                    {{ $status->status_name }}
                                </option>
                            @endforeach
                        </select>
                        @error('status_id')
                            <span class="invalid-feedback">{{ $message }}</span>
                        @enderror
                    </div>
                    <button type="submit" class="btn btn-primary w-100 rounded-pill font-weight-bold py-3">SIMPAN PERUBAHAN</button>
                </form>
            </div>

            <div class="card aura-card border-0 shadow-lg p-4">
                <h4 class="font-weight-bold mb-4 text-secondary border-bottom border-secondary pb-2">Order Summary</h4>
                
                @php
                    $additionsTotal = 0;
                    foreach($order->additions as $addition) {
                        if($addition->status_id == 2) {
                            $additionsTotal += $addition->items->sum('final_price');
                        }
                    }
                @endphp

                <div class="d-flex justify-content-between mb-2">
                    <span class="text-muted extra-small uppercase">Base Order</span>
                    <span class="text-white font-weight-bold">Rp {{ number_format($order->final_price ?? 0, 0, ',', '.') }}</span>
                </div>
                <div class="d-flex justify-content-between mb-3 border-bottom border-dark pb-2">
                    <span class="text-muted extra-small uppercase">Additions</span>
                    <span class="text-white font-weight-bold">+ Rp {{ number_format($additionsTotal, 0, ',', '.') }}</span>
                </div>

                <div class="d-flex justify-content-between align-items-center">
                    <span class="text-muted small uppercase font-weight-bold">Total Payable</span>
                    @if($order->final_price || $additionsTotal > 0)
                        <h3 class="text-secondary font-weight-bold mb-0">Rp {{ number_format(($order->final_price ?? 0) + $additionsTotal, 0, ',', '.') }}</h3>
                    @else
                        <h4 class="text-warning font-weight-bold mb-0">MENUNGGU HARGA</h4>
                    @endif
                </div>
            </div>
        </div>
    </div>
@endsection
