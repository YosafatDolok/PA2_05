@extends('layouts.app', ['page' => 'Notifikasi', 'pageSlug' => 'notifications'])

@section('content')
<div class="row">
    <div class="col-md-12">
        <div class="card aura-card border-0 shadow-sm">
            <div class="card-header border-0 bg-transparent p-4">
                <div class="d-flex justify-content-between align-items-center">
                    <div>
                        <h4 class="card-title text-dark fw-bold mb-1">Notifikasi</h4>
                    </div>
                    <form action="{{ route('admin.notifications.markAllRead') }}" method="POST">
                        @csrf
                        <button type="submit" class="btn btn-outline-danger btn-sm rounded-pill px-4">
                            <i class="fas fa-check-double me-2"></i> Tandai Semua Dibaca
                        </button>
                    </form>
                </div>
            </div>
            <div class="card-body p-0 mt-2">
                <div class="table-responsive">
                    <table class="table mb-0">
                        <thead>
                            <tr class="bg-light">
                                <th class="ps-4 py-3 text-muted small fw-bold text-uppercase tracking-wider" style="width: 80px;">Tipe</th>
                                <th class="py-3 text-muted small fw-bold text-uppercase tracking-wider">Detail Acara</th>
                                <th class="py-3 text-muted small fw-bold text-uppercase tracking-wider" style="width: 180px;">Waktu</th>
                                <th class="text-end pe-4 py-3 text-muted small fw-bold text-uppercase tracking-wider" style="width: 150px;">Aksi</th>
                            </tr>
                        </thead>
                        <tbody class="border-0">
                            @php \Carbon\Carbon::setLocale('id'); @endphp
                            @forelse($notifications as $notification)
                            <tr class="notification-row {{ $notification->is_read ? 'read-row' : 'unread-row' }}">
                                <td class="ps-4">
                                    <div class="aura-icon-circle-sm {{ $notification->type == 'new_order' ? 'bg-warning-transparent text-warning' : 'bg-aura-crimson-transparent text-aura-crimson' }}">
                                        <i class="fas {{ $notification->type == 'new_order' ? 'fa-shopping-basket' : 'fa-info-circle' }}"></i>
                                    </div>
                                </td>
                                <td>
                                    <div class="py-2">
                                        <p class="mb-1 fw-bold text-dark fs-6">{{ $notification->title }}</p>
                                        <p class="mb-0 text-muted smaller op-8">{{ $notification->message }}</p>
                                    </div>
                                </td>
                                <td>
                                    <div class="smaller">
                                        <div class="text-secondary fw-bold mb-1">{{ $notification->created_at->format('M d, Y') }}</div>
                                        <div class="text-danger fw-bold">{{ $notification->created_at->diffForHumans() }}</div>
                                    </div>
                                </td>
                                <td class="text-end pe-4">
                                    @if($notification->related_id)
                                        <a href="{{ route('orders.show', $notification->related_id) }}" class="btn btn-link btn-sm text-secondary text-decoration-none">
                                            <i class="fas fa-external-link-alt me-2"></i> Detail
                                        </a>
                                    @endif
                                </td>
                            </tr>
                            @empty
                            <tr>
                                <td colspan="4" class="text-center py-5">
                                    <div class="opacity-50 mb-3">
                                        <i class="far fa-bell-slash fs-1 text-muted"></i>
                                    </div>
                                    <p class="text-muted fw-bold">Belum ada pemberitahuan</p>
                                </td>
                            </tr>
                            @endforelse
                        </tbody>
                    </table>
                </div>
            </div>
            <div class="card-footer py-4 bg-transparent border-0 d-flex justify-content-center">
                <div class="aura-pagination">
                    {{ $notifications->links('pagination::bootstrap-5') }}
                </div>
            </div>
        </div>
    </div>
</div>

<style>
    .notification-row { transition: all 0.3s ease; border-bottom: 1px solid rgba(0,0,0,0.05) !important; }
    .notification-row:hover { background: rgba(0,0,0,0.02) !important; }
    .unread-row { background: rgba(255, 51, 75, 0.03) !important; border-left: 3px solid var(--aura-crimson); }
    .read-row { opacity: 0.75; }
    .tracking-wider { letter-spacing: 1px; }
</style>
@endsection
