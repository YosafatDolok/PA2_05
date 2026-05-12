@extends('layouts.app', ['page' => 'Notifications', 'pageSlug' => 'notifications'])

@section('content')
<div class="row">
    <div class="col-md-12">
        <div class="card aura-card shadow-lg">
            <div class="card-header border-0 bg-transparent p-4">
                <div class="d-flex justify-content-between align-items-center">
                    <div>
                        <h4 class="card-title text-white fw-bold mb-1">Intelligence Logs</h4>
                        <p class="small text-white-50 mb-0">System-wide event tracking and mission updates</p>
                    </div>
                    <form action="{{ route('admin.notifications.markAllRead') }}" method="POST">
                        @csrf
                        <button type="submit" class="btn btn-aura-crimson-outline btn-sm rounded-pill px-4">
                            <i class="fas fa-check-double me-2"></i> Clear All Unread
                        </button>
                    </form>
                </div>
            </div>
            <div class="card-body p-0 mt-2">
                <div class="table-responsive">
                    <table class="table mb-0">
                        <thead>
                            <tr class="bg-white-5">
                                <th class="ps-4 py-3 text-white-50 small fw-bold text-uppercase tracking-wider" style="width: 80px;">Type</th>
                                <th class="py-3 text-white-50 small fw-bold text-uppercase tracking-wider">Event Details</th>
                                <th class="py-3 text-white-50 small fw-bold text-uppercase tracking-wider" style="width: 180px;">Timestamp</th>
                                <th class="text-end pe-4 py-3 text-white-50 small fw-bold text-uppercase tracking-wider" style="width: 150px;">Control</th>
                            </tr>
                        </thead>
                        <tbody class="border-0">
                            @forelse($notifications as $notification)
                            <tr class="notification-row {{ $notification->is_read ? 'read-row' : 'unread-row' }}">
                                <td class="ps-4">
                                    <div class="aura-icon-circle-sm {{ $notification->type == 'new_order' ? 'bg-warning-transparent text-warning' : 'bg-aura-crimson-transparent text-aura-crimson' }}">
                                        <i class="fas {{ $notification->type == 'new_order' ? 'fa-shopping-basket' : 'fa-info-circle' }}"></i>
                                    </div>
                                </td>
                                <td>
                                    <div class="py-2">
                                        <p class="mb-1 fw-bold text-white fs-6">{{ $notification->title }}</p>
                                        <p class="mb-0 text-white-50 smaller op-8">{{ $notification->message }}</p>
                                    </div>
                                </td>
                                <td>
                                    <div class="smaller">
                                        <div class="text-white fw-bold mb-1">{{ $notification->created_at->format('M d, Y') }}</div>
                                        <div class="text-aura-crimson fw-bold">{{ $notification->created_at->diffForHumans() }}</div>
                                    </div>
                                </td>
                                <td class="text-end pe-4">
                                    @if($notification->related_id)
                                        <a href="{{ route('orders.show', $notification->related_id) }}" class="btn btn-link btn-sm text-white-50 text-decoration-none hover-white">
                                            <i class="fas fa-external-link-alt me-2"></i> Details
                                        </a>
                                    @endif
                                </td>
                            </tr>
                            @empty
                            <tr>
                                <td colspan="4" class="text-center py-5">
                                    <div class="op-2 mb-3">
                                        <i class="far fa-bell-slash fs-1 text-white"></i>
                                    </div>
                                    <p class="text-white-50 fw-bold">Zero active transmissions in logs</p>
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
    .aura-card {
        background: rgba(18, 18, 24, 0.95) !important;
        backdrop-filter: blur(20px);
    }
    .bg-white-5 { background: rgba(255, 255, 255, 0.02); }
    .notification-row { transition: all 0.3s ease; border-bottom: 1px solid rgba(255,255,255,0.03) !important; }
    .notification-row:hover { background: rgba(255,255,255,0.02) !important; }
    .unread-row { background: rgba(255, 51, 75, 0.03) !important; border-left: 3px solid var(--aura-crimson); }
    .read-row { opacity: 0.65; }
    .hover-white:hover { color: white !important; }
    .tracking-wider { letter-spacing: 1.5px; }
    
    /* Premium Pagination Overrides */
    .aura-pagination .pagination { gap: 8px; margin-bottom: 0; }
    .aura-pagination .page-item .page-link {
        background: rgba(255,255,255,0.05) !important;
        border: 1px solid rgba(255,255,255,0.1) !important;
        color: rgba(255,255,255,0.8) !important;
        border-radius: 10px !important;
        padding: 10px 18px !important;
        transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1);
        box-shadow: none !important;
    }
    .aura-pagination .page-item.active .page-link {
        background: var(--aura-crimson) !important;
        border-color: var(--aura-crimson) !important;
        color: white !important;
        box-shadow: 0 5px 15px rgba(255, 51, 75, 0.4) !important;
    }
    .aura-pagination .page-item:hover:not(.active) .page-link {
        background: rgba(255,255,255,0.12) !important;
        color: white !important;
        transform: translateY(-2px);
    }
    .aura-pagination .page-item.disabled .page-link {
        background: rgba(255,255,255,0.02) !important;
        border-color: rgba(255,255,255,0.03) !important;
        color: rgba(255,255,255,0.2) !important;
    }
</style>
@endsection
