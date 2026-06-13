@extends('layouts.app', [
    'page' => __('Detail Pesanan'),
    'pageSlug' => 'orders'
])

@section('content')
    <div class="d-flex justify-content-between align-items-center mb-5">
        <div>
        <div class="d-flex align-items-center gap-3">
            <h2 class="m-0 font-weight-bold">Pesanan #ORD-{{ str_pad($order->order_id, 5, '0', STR_PAD_LEFT) }}</h2>
            <span class="badge {{ $order->status_id == 9 ? 'bg-danger-light' : 'bg-primary-light' }} py-2 px-3 rounded-pill">
                {{ strtoupper($order->status->status_name) }}
            </span>
        </div>
        <p class="text-muted small uppercase letter-spacing-1 mb-0 mt-1">Tampilan detail dan manajemen status</p>
        </div>
        <div class="d-flex align-items-center">
            <a href="{{ route('orders.invoice', $order->order_id) }}" class="btn btn-primary btn-sm rounded-pill px-4 font-weight-bold mr-2">
                <i class="fas fa-file-pdf mr-2"></i> EKSPOR PDF / FAKTUR
            </a>
            <a href="{{ route('orders.index') }}" class="btn btn-secondary btn-icon rounded-circle">
                <i class="fas fa-arrow-left"></i>
            </a>
        </div>
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

    @if($order->status_id == 4 && $order->remaining_balance > 0)
        <div class="alert alert-danger aura-card mb-4 border-0 shadow-lg animate-pulse" style="background: rgba(244, 67, 54, 0.1); border-left: 5px solid #f44336 !important; color: #ff5252;">
            <div class="d-flex align-items-center">
                <i class="fas fa-money-bill-wave fa-2x mr-3"></i>
                <div>
                    <h5 class="font-weight-bold m-0 text-white">TERKIRIM TAPI BELUM LUNAS!</h5>
                    <span class="small">Pesanan ini sudah dikirim tetapi pelanggan masih memiliki sisa tagihan sebesar <strong class="text-white">Rp {{ number_format($order->remaining_balance, 0, ',', '.') }}</strong>.</span>
                </div>
            </div>
        </div>
    @endif

    <div class="row">
        <div class="col-md-8">
            <div class="card aura-card border-0 shadow-lg p-4 mb-4">
                <h4 class="font-weight-bold mb-4 text-secondary border-bottom border-secondary pb-2">Menu yang Dipesan</h4>
                <form action="{{ route('orders.updateItemPrices', $order->order_id) }}" method="POST">
                    @csrf
                    <div class="table-responsive">
                        <table class="table text-white mb-0">
                            <thead>
                                <tr class="text-muted extra-small uppercase">
                                    <th>Nama Menu</th>
                                    <th style="width: 250px;">Harga (Rp)</th>
                                    <th class="text-right">Aksi</th>
                                </tr>
                            </thead>
                            <tbody>
                                @foreach($order->items as $item)
                                <tr>
                                    <td class="py-3">
                                        <div class="d-flex align-items-center">
                                            <div class="menu-dot mr-3"></div>
                                            <span class="font-weight-bold">{{ $item->menu->name ?? 'Item Tidak Diketahui' }}</span>
                                        </div>
                                    </td>
                                    <td class="py-2">
                                        <input type="text" class="form-control item-price-input" 
                                               data-item-id="{{ $item->order_item_id }}"
                                               value="{{ $item->final_price ? number_format($item->final_price, 0, ',', '') : '' }}"
                                               placeholder="0" {{ $order->status_id > 1 ? 'readonly' : '' }}>
                                        <input type="hidden" name="prices[{{ $item->order_item_id }}]" class="item-price-hidden" 
                                               value="{{ $item->final_price ? intval($item->final_price) : '' }}">
                                    </td>
                                    <td class="text-right py-3">
                                        <a href="{{ route('menus.edit', $item->menu_id) }}" class="btn btn-link btn-sm text-secondary p-0">Lihat Menu</a>
                                    </td>
                                </tr>
                                @endforeach
                            </tbody>
                        </table>
                    </div>
                    @if($order->status_id == 1)
                    <div class="text-right mt-3">
                        <button type="submit" class="btn btn-sm btn-primary rounded-pill px-4">
                            <i class="fas fa-save mr-1"></i> Simpan Harga
                        </button>
                    </div>
                    @endif
                </form>
            </div>

            @if($order->additions->count() > 0)
            <div id="additions-section" class="card aura-card border-0 shadow-lg p-4 mb-4">
                <h4 class="font-weight-bold mb-4 text-secondary border-bottom border-secondary pb-2">Menu Tambahan (Additions)</h4>
                @foreach($order->additions as $addition)
                    <div class="addition-request mb-4 p-3 rounded bg-light" style="border-left: 3px solid {{ $addition->status_id == 1 ? '#ff9800' : ($addition->status_id == 2 ? '#4caf50' : '#f44336') }}">
                        <div class="d-flex justify-content-between align-items-start mb-3">
                            <div>
                                <span class="badge {{ $addition->status_id == 1 ? 'bg-warning' : ($addition->status_id == 2 ? 'bg-success' : 'bg-danger') }} small uppercase mb-2">
                                    {{ $addition->status->status_name }}
                                </span>
                                <p class="text-muted extra-small mb-0">Tanggal Permintaan: {{ $addition->created_at->format('d M Y, H:i') }}</p>
                            </div>
                            @if($addition->status_id == 2)
                                <h5 class="text-secondary font-weight-bold">Rp {{ number_format($addition->items->sum('final_price'), 0, ',', '.') }}</h5>
                            @endif
                        </div>

                        <ul class="list-unstyled mb-3">
                            @foreach($addition->items as $item)
                                <li class="text-dark d-flex justify-content-between">
                                    <span>• {{ $item->menu->name ?? 'Item Tidak Diketahui' }}</span>
                                    @if($addition->status_id == 2)
                                        <span class="text-muted small">Rp {{ number_format($item->final_price, 0, ',', '.') }}</span>
                                    @endif
                                </li>
                            @endforeach
                        </ul>

                        @if($addition->notes)
                            <div class="bg-white border p-2 rounded mb-3">
                                <p class="text-muted extra-small italic mb-0">"{{ $addition->notes }}"</p>
                            </div>
                        @endif

                        @if($addition->status_id == 1)
                            <form action="{{ route('additions.approve', $addition->id) }}" method="POST" class="mt-3">
                                @csrf
                                <div class="row align-items-end">
                                    @foreach($addition->items as $item)
                                        <div class="col-md-6 mb-2">
                                            <label class="extra-small text-muted mb-1">Harga {{ $item->menu->name ?? 'Item Tidak Diketahui' }} (Rp)</label>
                                            <input type="text" class="form-control form-control-sm addition-price-input @error('prices.'.$item->id) is-invalid @enderror" 
                                                   placeholder="Harga per request..."
                                                   value="{{ old('prices.'.$item->id, $item->final_price) ? number_format(old('prices.'.$item->id, $item->final_price), 0, ',', '.') : '' }}">
                                            <input type="hidden" name="prices[{{ $item->id }}]" class="addition-price-hidden"
                                                   value="{{ old('prices.'.$item->id, $item->final_price) }}">
                                            @error('prices.'.$item->id)
                                                <span class="invalid-feedback d-block">{{ $message }}</span>
                                            @enderror
                                        </div>
                                    @endforeach
                                    <div class="col-12 mt-2">
                                        <button type="submit" formaction="{{ route('additions.save-prices', $addition->id) }}" class="btn btn-outline-success btn-sm rounded-pill px-4 mr-2 font-weight-bold text-uppercase">SIMPAN HARGA (TANPA GANTI STATUS)</button>
                                        <button type="submit" class="btn btn-primary btn-sm rounded-pill px-4 font-weight-bold text-uppercase">SETUJUI & TETAPKAN HARGA</button>
                                        <button type="submit" form="reject-form-{{ $addition->id }}" class="btn btn-outline-danger btn-sm rounded-pill px-4 font-weight-bold text-uppercase ml-2">TOLAK</button>
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
                <h4 class="font-weight-bold mb-4 text-secondary border-bottom border-secondary pb-2">Info Pelanggan & Acara</h4>
                <div class="row mb-3">
                    <div class="col-sm-4 text-muted small uppercase">Nama Pelanggan</div>
                    <div class="col-sm-8 text-dark font-weight-bold">{{ $order->user->name }}</div>
                </div>
                @if($order->user->email)
                <div class="row mb-3">
                    <div class="col-sm-4 text-muted small uppercase">Email</div>
                    <div class="col-sm-8 text-dark">{{ $order->user->email }}</div>
                </div>
                @endif
                @if($order->user->phone_number)
                <div class="row mb-3">
                    <div class="col-sm-4 text-muted small uppercase">No. Telepon</div>
                    <div class="col-sm-8 text-dark">{{ $order->user->phone_number }}</div>
                </div>
                @endif
                <div class="row mb-3">
                    <div class="col-sm-4 text-muted small uppercase">Alamat Acara</div>
                    <div class="col-sm-8 text-dark">
                        {{ $order->event_address }}
                        @if($order->event_latitude && $order->event_longitude)
                            <div class="mt-2">
                                <a href="https://www.google.com/maps/search/?api=1&query={{ $order->event_latitude }},{{ $order->event_longitude }}" 
                                   target="_blank" class="btn btn-sm" style="background-color: rgba(230, 57, 70, 0.1); color: #e63946; border: 1px solid rgba(230, 57, 70, 0.2); border-radius: 20px; font-size: 11px; padding: 4px 10px;">
                                    <i class="fas fa-map-marker-alt mr-1"></i> Buka di Google Maps
                                </a>
                            </div>
                        @endif
                    </div>
                </div>
                <div class="row mb-3">
                    <div class="col-sm-4 text-muted small uppercase">Tanggal Acara</div>
                    <div class="col-sm-8 text-dark">{{ $order->event_date->format('l, d F Y') }}</div>
                </div>
                <div class="row mb-3">
                    <div class="col-sm-4 text-muted small uppercase">Kapasitas</div>
                    <div class="col-sm-8 text-dark">{{ $order->people }} Orang</div>
                </div>
                <div class="row">
                    <div class="col-sm-4 text-muted small uppercase">Catatan</div>
                    <div class="col-sm-8 text-dark italic-placeholder">{{ $order->notes ?? 'Tidak ada catatan khusus' }}</div>
                </div>
            </div>

            <div class="card aura-card border-0 shadow-lg p-4">
                <h4 class="font-weight-bold mb-4 text-secondary border-bottom border-secondary pb-2">Info Pengiriman</h4>
                <div class="row mb-3">
                    <div class="col-sm-4 text-muted small uppercase">Status</div>
                    <div class="col-sm-8">
                        <span class="badge bg-primary-light">{{ strtoupper($order->status->status_name) }}</span>
                    </div>
                </div>
                @if($order->delivered_at)
                <div class="row mb-3">
                    <div class="col-sm-4 text-muted small uppercase">Terkirim Pada</div>
                    <div class="col-sm-8 text-dark">{{ $order->delivered_at->format('d M Y, H:i') }}</div>
                </div>
                @endif
                <div class="row">
                    <div class="col-sm-4 text-muted small uppercase">Catatan Lokasi</div>
                    <div class="col-sm-8 text-dark">{{ $order->location_notes ?? '-' }}</div>
                </div>
            </div>
        </div>

        <div class="col-md-4">
            <div class="card aura-card border-0 shadow-lg p-4 mb-4">
                <div class="d-flex justify-content-between align-items-center mb-4 border-bottom border-secondary pb-2">
                    <h4 class="font-weight-bold m-0 text-secondary">Kelola Pesanan</h4>
                    <a href="{{ route('orders.chat', $order->order_id) }}" class="btn btn-secondary btn-sm rounded-pill px-3">
                        <i class="fas fa-comments mr-2"></i> BUKA CHAT
                    </a>
                </div>
                
                <form id="order-action-form" action="{{ route('orders.updateStatus', $order->order_id) }}" method="POST">
                    @csrf
                    @method('PATCH')
                    
                    {{-- Hidden status field to be updated by buttons --}}
                    <input type="hidden" name="status_id" id="next_status_id" value="{{ $order->status_id }}">

                    <div class="mb-4">
                        <label class="text-muted small uppercase mb-2 d-block">Harga Final (Rp)</label>
                        <input type="text" id="final_price_display" value="{{ old('final_price', $order->final_price ? number_format($order->final_price, 0, ',', '.') : '') }}" 
                               class="form-control" 
                               placeholder="Menghitung total..." readonly>
                        <input type="hidden" name="final_price" id="final_price_actual" value="{{ old('final_price', $order->final_price ? intval($order->final_price) : '') }}">
                        
                        <script>
                            document.addEventListener('DOMContentLoaded', function() {
                                const displayInput = document.getElementById('final_price_display');
                                const actualInput = document.getElementById('final_price_actual');
                                const priceInputs = document.querySelectorAll('.item-price-input');
                                
                                // Approved additions sum (server-rendered constant)
                                const approvedAdditionsTotal = {{ $order->additions->where('status_id', 2)->sum(function($add) { return $add->items->sum('final_price'); }) }};

                                function calculateTotal() {
                                    let total = approvedAdditionsTotal;
                                    
                                    priceInputs.forEach(input => {
                                        let rawValue = input.value.replace(/[^0-9]/g, '');
                                        if (rawValue) {
                                            total += parseInt(rawValue, 10);
                                        }
                                        
                                        // Update hidden inputs for submission
                                        let hiddenInput = input.parentElement.querySelector('.item-price-hidden');
                                        if (hiddenInput) {
                                            hiddenInput.value = rawValue;
                                        }
                                    });

                                    // Format individual input display
                                    priceInputs.forEach(input => {
                                        let rawValue = input.value.replace(/[^0-9]/g, '');
                                        if (rawValue) {
                                            let selectionStart = input.selectionStart;
                                            let oldLen = input.value.length;
                                            input.value = parseInt(rawValue, 10).toLocaleString('id-ID');
                                            let diff = input.value.length - oldLen;
                                            input.setSelectionRange(selectionStart + diff, selectionStart + diff);
                                        } else {
                                            input.value = '';
                                        }
                                    });

                                    if (displayInput) {
                                        displayInput.value = total > 0 ? total.toLocaleString('id-ID') : '';
                                        actualInput.value = total;
                                    }
                                }

                                priceInputs.forEach(input => {
                                    input.addEventListener('input', calculateTotal);
                                });

                                // Format addition price inputs
                                const additionPriceInputs = document.querySelectorAll('.addition-price-input');
                                additionPriceInputs.forEach(input => {
                                    input.addEventListener('input', function() {
                                        let rawValue = input.value.replace(/[^0-9]/g, '');
                                        let hiddenInput = input.parentElement.querySelector('.addition-price-hidden');
                                        
                                        if (hiddenInput) {
                                            hiddenInput.value = rawValue;
                                        }
                                        
                                        if (rawValue) {
                                            let selectionStart = input.selectionStart;
                                            let oldLen = input.value.length;
                                            input.value = parseInt(rawValue, 10).toLocaleString('id-ID');
                                            let diff = input.value.length - oldLen;
                                            input.setSelectionRange(selectionStart + diff, selectionStart + diff);
                                        } else {
                                            input.value = '';
                                        }
                                    });
                                });

                                // Initialize totals and formats on load
                                calculateTotal();
                            });
                        </script>
                        @if($order->status_id > 1)
                            <small class="text-muted mt-1">Harga tidak dapat diubah setelah pesanan diproses.</small>
                        @endif
                        @error('final_price')
                            <span class="invalid-feedback">{{ $message }}</span>
                        @enderror
                    </div>

                    <hr class="border-secondary my-4">

                    <div class="workflow-actions">
                        @if($order->is_cancelling)
                            <div class="aura-card border-warning mb-4 p-4" style="background: rgba(255, 171, 0, 0.03); border-color: rgba(255, 171, 0, 0.3) !important;">
                                <div class="d-flex align-items-center mb-3">
                                    <div class="stat-icon mr-3" style="background: rgba(255, 171, 0, 0.1); border-color: rgba(255, 171, 0, 0.2); color: #ffab00; width: 45px; height: 45px;">
                                        <i class="fas fa-exclamation-triangle" style="font-size: 1.1rem;"></i>
                                    </div>
                                    <div>
                                        <h5 class="m-0 font-weight-bold" style="color: #ffab00;">Permintaan Pembatalan</h5>
                                        <p class="small text-muted mb-0">Pelanggan meminta untuk membatalkan pesanan ini.</p>
                                    </div>
                                </div>
                                <div class="p-3 rounded mb-4" style="background: rgba(0,0,0,0.3); border-left: 3px solid #ffab00;">
                                    <p class="mb-1 text-muted extra-small font-weight-bold uppercase letter-spacing-1" style="font-size: 10px;">ALASAN PELANGGAN:</p>
                                    <p class="mb-0 text-white italic" style="font-size: 13px; line-height: 1.5;">"{{ $order->cancel_reason }}"</p>
                                </div>
                                <div class="row g-2">
                                    <div class="col-6">
                                        <button type="button" onclick="handleCancel('approve')" class="btn btn-success w-100 rounded-pill font-weight-bold py-2 shadow-sm">
                                            <i class="fas fa-check mr-2"></i> SETUJUI
                                        </button>
                                    </div>
                                    <div class="col-6">
                                        <button type="button" onclick="handleCancel('reject')" class="btn btn-secondary w-100 rounded-pill font-weight-bold py-2">
                                            <i class="fas fa-times mr-2"></i> TOLAK
                                        </button>
                                    </div>
                                </div>
                            </div>
                        @endif

                        @if($order->status_id == 9)
                            <div class="alert alert-dark border-0 text-center py-4 rounded-3 shadow-sm mb-0">
                                <i class="fas fa-times-circle fa-2x mb-2 d-block"></i>
                                <span class="font-weight-bold uppercase letter-spacing-1">PESANAN DIBATALKAN</span>
                                <p class="small text-muted mb-0 mt-2">Tidak ada tindakan lebih lanjut yang diperlukan.</p>
                            </div>
                        @elseif($order->status_id == 1) {{-- Pending --}}
                            <button type="button" onclick="submitStatus(2)" class="btn btn-success w-100 rounded-pill font-weight-bold py-3 mb-3 shadow-lg">
                                <i class="fas fa-check-circle mr-2"></i> KONFIRMASI & PROSES
                            </button>
                            <button type="button" onclick="submitStatus(9)" class="btn btn-danger w-100 rounded-pill py-2 font-weight-bold text-white shadow-sm">
                                <i class="fas fa-times-circle mr-1"></i> Batalkan Pesanan
                            </button>
                        @elseif($order->status_id == 2) {{-- Preparing --}}
                            <button type="button" onclick="submitStatus(3)" class="btn btn-info w-100 rounded-pill font-weight-bold py-3 shadow-lg" style="background: #00bcd4; border: none;">
                                <i class="fas fa-truck mr-2"></i> SIAP DIKIRIM
                            </button>
                        @elseif($order->status_id == 3) {{-- Out for Delivery --}}
                            <button type="button" onclick="submitStatus(4)" class="btn btn-success w-100 rounded-pill font-weight-bold py-3 shadow-lg">
                                <i class="fas fa-home mr-2"></i> TANDAI TELAH DIKIRIM (DELIVERED)
                            </button>
                        @elseif($order->status_id == 4) {{-- Delivered --}}
                            <div class="alert alert-success border-0 text-center py-3">
                                <i class="fas fa-check-double mr-2"></i> PESANAN TELAH SELESAI
                            </div>
                        @endif

                        @if($order->status_id < 4 && $order->status_id != 9)
                            <div class="text-center mt-3">
                                <button type="submit" class="btn btn-link btn-sm text-muted">Hanya Simpan Perubahan (Tanpa Ganti Status)</button>
                            </div>
                        @endif
                    </div>
                </form>
            </div>

            <!-- DRIVER MANAGEMENT CARD -->
            <div class="card aura-card border-0 shadow-lg p-4 mb-4">
                <h4 class="font-weight-bold mb-4 text-secondary border-bottom border-secondary pb-2">Kelola Sopir</h4>
                
                <form action="{{ route('orders.assignDriver', $order->order_id) }}" method="POST">
                    @csrf
                    
                    <div class="mb-4">
                        <label class="text-muted small uppercase mb-2 d-block">Tugaskan Sopir</label>
                        <select name="driver_id" class="form-control bg-dark border-secondary text-white @error('driver_id') is-invalid @enderror" onchange="this.form.submit()">
                            <option value="">-- Belum Ada Sopir --</option>
                            @foreach($drivers as $driver)
                                @php
                                    $isAtCapacity = $driver->active_deliveries >= 3;
                                    $color = $isAtCapacity ? '#e63946' : ($driver->active_deliveries > 0 ? '#ff9800' : '#4caf50');
                                @endphp
                                <option value="{{ $driver->user_id }}" {{ old('driver_id', $order->driver_id) == $driver->user_id ? 'selected' : '' }} 
                                    style="color: {{ $color }}" {{ $isAtCapacity && $order->driver_id != $driver->user_id ? 'disabled' : '' }}>
                                    {{ $driver->name }} 
                                    @if($isAtCapacity)
                                        (KAPASITAS PENUH - 3 Pengiriman)
                                    @elseif($driver->active_deliveries > 0)
                                        (SIBUK - {{ $driver->active_deliveries }} Pengiriman)
                                    @else
                                        (TERSEDIA)
                                    @endif
                                </option>
                            @endforeach
                        </select>
                        @error('driver_id')
                            <span class="invalid-feedback">{{ $message }}</span>
                        @enderror
                        <small class="text-muted mt-2 d-block"><i class="fas fa-info-circle mr-1"></i> Kapasitas maksimal driver adalah 3 pesanan aktif bersamaan. Memilih driver akan langsung menyimpannya.</small>
                    </div>
                </form>
            </div>

            <!-- ORDER SUMMARY CARD -->
                <h4 class="font-weight-bold mb-4 text-secondary border-bottom border-secondary pb-2">Ringkasan Pesanan</h4>
                
                @php
                    $additionsTotal = 0;
                    foreach($order->additions as $addition) {
                        if($addition->status_id == 2) {
                            $additionsTotal += $addition->items->sum('final_price');
                        }
                    }
                @endphp

                <div class="d-flex justify-content-between mb-2">
                    <span class="text-muted extra-small uppercase">Pesanan Dasar</span>
                    <span class="text-white font-weight-bold">Rp {{ number_format($order->final_price ?? 0, 0, ',', '.') }}</span>
                </div>
                <div class="d-flex justify-content-between mb-3 border-bottom border-dark pb-2">
                    <span class="text-muted extra-small uppercase">Tambahan</span>
                    <span class="text-white font-weight-bold">+ Rp {{ number_format($additionsTotal, 0, ',', '.') }}</span>
                </div>

                <div class="d-flex justify-content-between align-items-center">
                    <span class="text-muted small uppercase font-weight-bold">Total Tagihan</span>
                    @if($order->final_price || $additionsTotal > 0)
                        <h3 class="text-secondary font-weight-bold mb-0">Rp {{ number_format($order->total_payable, 0, ',', '.') }}</h3>
                    @else
                        <h4 class="text-warning font-weight-bold mb-0">MENUNGGU HARGA</h4>
                    @endif
                </div>

                <div class="mt-4 pt-3 border-top border-dark">
                    <div class="d-flex justify-content-between mb-2">
                        <span class="text-muted extra-small uppercase">Total Dibayar</span>
                        <span class="text-success font-weight-bold">Rp {{ number_format($order->total_paid, 0, ',', '.') }}</span>
                    </div>
                    
                    @if($order->total_payable > $order->total_paid)
                        <div class="alert alert-warning border-0 p-2 text-center mt-2 mb-0" style="background: rgba(255, 152, 0, 0.1); color: #ff9800;">
                            <i class="fas fa-exclamation-triangle mr-2"></i>
                            <span class="extra-small font-weight-bold">SISA TAGIHAN: Rp {{ number_format($order->total_payable - $order->total_paid, 0, ',', '.') }}</span>
                        </div>
                    @elseif($order->total_paid > 0 && $order->total_paid >= $order->total_payable)
                        <div class="alert alert-success border-0 p-2 text-center mt-2 mb-0" style="background: rgba(76, 175, 80, 0.1); color: #4caf50;">
                            <i class="fas fa-check-double mr-2"></i>
                            <span class="extra-small font-weight-bold">LUNAS</span>
                        </div>
                    @endif
                </div>
            </div>

            {{-- ACTIVITY TIMELINE --}}
            <div class="card aura-card border-0 shadow-lg p-4">
                <h4 class="font-weight-bold mb-4 text-secondary border-bottom border-secondary pb-2">Log Aktivitas</h4>
                <div class="activity-timeline mt-3">
                    @forelse($order->activities as $activity)
                        <div class="timeline-item mb-0 pb-4 position-relative">
                            {{-- Vertical Line --}}
                            @if(!$loop->last)
                                <div class="position-absolute" style="left: 11px; top: 25px; bottom: 0; width: 2px; background: rgba(255,255,255,0.05);"></div>
                            @endif
                            
                            <div class="d-flex align-items-start">
                                <div class="activity-icon-container d-flex justify-content-center align-items-center rounded-circle mr-3" 
                                     style="width: 24px; height: 24px; background: rgba(255,255,255,0.03); min-width: 24px;">
                                    @if($activity->type == 'status_change')
                                        <i class="fas fa-sync-alt text-primary" style="font-size: 10px;"></i>
                                    @elseif($activity->type == 'price_set')
                                        <i class="fas fa-tag text-warning" style="font-size: 10px;"></i>
                                    @elseif($activity->type == 'driver_assigned')
                                        <i class="fas fa-truck text-info" style="font-size: 10px;"></i>
                                    @elseif($activity->type == 'addition_approved')
                                        <i class="fas fa-plus-circle text-success" style="font-size: 10px;"></i>
                                    @else
                                        <i class="fas fa-info-circle text-muted" style="font-size: 10px;"></i>
                                    @endif
                                </div>
                                <div class="flex-grow-1">
                                    <p class="text-white small mb-1 font-weight-bold">{{ $activity->description }}</p>
                                    <div class="d-flex justify-content-between align-items-center">
                                        <span class="text-muted extra-small uppercase" style="font-size: 9px;">Oleh: {{ $activity->user->name }}</span>
                                        <span class="text-muted extra-small" style="font-size: 9px;">{{ $activity->created_at->diffForHumans() }}</span>
                                    </div>
                                </div>
                            </div>
                        </div>
                    @empty
                        <p class="text-muted small italic text-center">Belum ada aktivitas tercatat.</p>
                    @endforelse
                </div>
            </div>
        </div>
    </div>

    {{-- Hidden form for cancellation request handling --}}
    <form id="cancelRequestForm" action="{{ route('orders.cancel-request', $order->order_id) }}" method="POST" style="display: none;">
        @csrf
        <input type="hidden" name="action" id="cancelActionInput">
    </form>

    {{-- Aura Confirmation Modal --}}
    <div id="auraConfirmModal" class="aura-modal-overlay">
        <div class="aura-modal-card">
            <div class="aura-modal-icon">
                <i class="fas fa-question-circle"></i>
            </div>
            <h4 id="auraConfirmTitle" class="mb-2 font-weight-bold">Konfirmasi</h4>
            <p id="auraConfirmMessage" class="text-muted small mb-4">Apakah Anda yakin ingin melanjutkan tindakan ini?</p>
            <div class="d-flex gap-2">
                <button type="button" onclick="closeAuraConfirm()" class="btn btn-secondary flex-grow-1 rounded-pill font-weight-bold">BATAL</button>
                <button type="button" id="auraConfirmBtn" class="btn btn-primary flex-grow-1 rounded-pill font-weight-bold shadow-lg">YA, LANJUTKAN</button>
            </div>
        </div>
    </div>

    <style>
        .aura-modal-overlay {
            position: fixed;
            top: 0;
            left: 0;
            width: 100%;
            height: 100%;
            background: rgba(0, 0, 0, 0.85);
            backdrop-filter: blur(10px);
            z-index: 9999;
            display: none;
            align-items: center;
            justify-content: center;
            opacity: 0;
            transition: opacity 0.3s ease;
        }
        .aura-modal-overlay.active {
            display: flex;
            opacity: 1;
        }
        .aura-modal-card {
            background: #16161e;
            border: 1px solid rgba(255, 255, 255, 0.1);
            border-radius: 30px;
            padding: 40px;
            width: 100%;
            max-width: 400px;
            text-align: center;
            transform: scale(0.8);
            transition: transform 0.3s cubic-bezier(0.34, 1.56, 0.64, 1);
            box-shadow: 0 25px 50px rgba(0, 0, 0, 0.5);
        }
        .aura-modal-overlay.active .aura-modal-card {
            transform: scale(1);
        }
        .aura-modal-icon {
            width: 70px;
            height: 70px;
            background: rgba(255, 51, 75, 0.1);
            border-radius: 20px;
            display: flex;
            align-items: center;
            justify-content: center;
            margin: 0 auto 20px;
            color: #ff334b;
            font-size: 2rem;
        }
        .gap-2 { gap: 10px; }

        /* Hide spinner arrows for number input */
        input[type=number]::-webkit-outer-spin-button,
        input[type=number]::-webkit-inner-spin-button {
            -webkit-appearance: none;
            margin: 0;
        }
        input[type=number] {
            -moz-appearance: textfield;
        }
    </style>

    <script>
        function submitStatus(statusId) {
            if (statusId == 9) {
                showAuraConfirm(
                    'Batalkan Pesanan', 
                    'Apakah Anda yakin ingin membatalkan pesanan ini secara permanen?',
                    function() {
                        document.getElementById('next_status_id').value = statusId;
                        document.getElementById('order-action-form').submit();
                    }
                );
                return;
            }
            
            document.getElementById('next_status_id').value = statusId;
            document.getElementById('order-action-form').submit();
        }

        function handleCancel(action) {
            const title = action === 'approve' ? 'Setujui Pembatalan' : 'Tolak Pembatalan';
            const msg = action === 'approve' 
                ? 'Apakah Anda yakin ingin menyetujui permintaan pembatalan dari pelanggan?' 
                : 'Apakah Anda yakin ingin menolak permintaan pembatalan ini?';
            
            showAuraConfirm(title, msg, function() {
                document.getElementById('cancelActionInput').value = action;
                document.getElementById('cancelRequestForm').submit();
            });
        }

        // Modal Engine
        let onAuraConfirm = null;

        function showAuraConfirm(title, message, callback) {
            document.getElementById('auraConfirmTitle').innerText = title;
            document.getElementById('auraConfirmMessage').innerText = message;
            onAuraConfirm = callback;
            
            const modal = document.getElementById('auraConfirmModal');
            modal.classList.add('active');
            
            document.getElementById('auraConfirmBtn').onclick = function() {
                if (onAuraConfirm) onAuraConfirm();
                closeAuraConfirm();
            };
        }

        function closeAuraConfirm() {
            const modal = document.getElementById('auraConfirmModal');
            modal.classList.remove('active');
            onAuraConfirm = null;
        }
    </script>
@endsection
