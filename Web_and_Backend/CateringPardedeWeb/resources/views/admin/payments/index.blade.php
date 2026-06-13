@extends('layouts.app', [
    'page' => __('Riwayat Pembayaran'),
    'pageSlug' => 'payments'
])

@section('content')
    <div class="d-flex justify-content-between align-items-center mb-5">
        <div>
            <h2 class="m-0 font-weight-bold text-white">Riwayat Pembayaran</h2>
            <p class="text-muted small uppercase letter-spacing-1 mb-0">Pantau semua transaksi Midtrans yang masuk</p>
        </div>
    </div>

    <div class="row">
        <div class="col-12">
            <div class="card aura-card border-0 shadow-lg">
                <div class="table-responsive">
                    <table class="table align-items-center mb-0">
                        <thead class="text-secondary uppercase extra-small font-weight-bold">
                            <tr>
                                <th>ID TRANSAKSI</th>
                                <th>PESANAN</th>
                                <th>JUMLAH</th>
                                <th>METODE</th>
                                <th>STATUS</th>
                                <th>WAKTU</th>
                            </tr>
                        </thead>
                        <tbody class="text-white">
                            @forelse($payments as $payment)
                            <tr>
                                <td>
                                    <div class="font-weight-bold text-crimson">PMT-{{ str_pad($payment['id'], 6, '0', STR_PAD_LEFT) }}</div>
                                    @if(!empty($payment['midtrans_id']))
                                        <div class="extra-small text-muted" style="font-size: 11px;" title="{{ $payment['midtrans_id'] }}">
                                            Ref: {{ substr($payment['midtrans_id'], 0, 8) }}...
                                        </div>
                                    @endif
                                </td>
                                <td>
                                    <a href="{{ route('orders.show', $payment['order_id']) }}" class="text-white-50">
                                        #ORD-{{ str_pad($payment['order_id'], 5, '0', STR_PAD_LEFT) }}
                                    </a>
                                </td>
                                <td>
                                    <span class="font-weight-bold text-white">Rp {{ number_format($payment['amount'], 0, ',', '.') }}</span>
                                </td>
                                <td>
                                    <span class="badge bg-secondary-light extra-small">
                                        {{ strtoupper($payment['payment_type'] ?? $payment['payment_method']) }}
                                    </span>
                                </td>
                                <td>
                                    @php
                                        $statusClass = 'badge ';
                                        switch($payment['status']) {
                                            case 'settlement': case 'paid': $statusClass .= 'bg-success-light'; break;
                                            case 'pending': $statusClass .= 'bg-warning-light'; break;
                                            case 'expire': case 'cancel': case 'deny': $statusClass .= 'bg-crimson'; break;
                                            default: $statusClass .= 'bg-secondary-light';
                                        }
                                    @endphp
                                    <span class="{{ $statusClass }}">{{ strtoupper($payment['status']) }}</span>
                                </td>
                                <td>
                                    <div class="small">{{ \Carbon\Carbon::parse($payment['created_at'])->format('d M Y') }}</div>
                                    <div class="extra-small text-muted">{{ \Carbon\Carbon::parse($payment['created_at'])->format('H:i') }}</div>
                                </td>
                            </tr>
                            @empty
                            <tr>
                                <td colspan="6" class="text-center py-5">
                                    <div class="text-muted">Belum ada riwayat pembayaran yang ditemukan.</div>
                                </td>
                            </tr>
                            @endforelse
                        </tbody>
                    </table>
                </div>
            </div>
        </div>
    </div>
@endsection
