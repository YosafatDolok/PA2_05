@extends('layouts.app', [
    'page' => __('Messages Inbox'),
    'pageSlug' => 'messages'
])

@section('content')
    <div class="d-flex justify-content-between align-items-center mb-5">
        <div>
            <h2 class="m-0 font-weight-bold">Daftar Pesan</h2>
            <p class="text-muted small uppercase letter-spacing-1 mb-0">Kelola diskusi dan pertanyaan pelanggan</p>
        </div>
    </div>

    <div class="row">
        <div class="col-12">
            <div class="card aura-card border-0 shadow-lg bg-transparent">
                <div class="table-responsive">
                    <table class="table align-items-center mb-0" style="border-separate: separate; border-spacing: 0 12px;">
                        <thead>
                            <tr class="text-muted extra-small uppercase border-0">
                                <th class="ps-4 border-0">Pelanggan</th>
                                <th class="border-0">Pesan Terakhir</th>
                                <th class="border-0">Info Pesanan</th>
                                <th class="border-0">Status</th>
                                <th class="text-center border-0">Aksi</th>
                            </tr>
                        </thead>
                        <tbody>
                            @forelse($orders as $order)
                                @php
                                    $lastMessage = $order->messages->first();
                                    $isUnread = $order->unread_messages_count > 0;
                                @endphp
                                <tr class="inbox-row {{ $isUnread ? 'unread-thread' : '' }}" id="order-row-{{ $order->order_id }}">
                                    <td class="ps-4 py-4 rounded-start">
                                        <div class="d-flex align-items-center">
                                            <div class="avatar-container position-relative" style="margin-right: 35px;">
                                                <div class="avatar-premium">
                                                    {{ substr($order->user->name, 0, 1) }}
                                                </div>
                                            </div>
                                            <div class="lh-sm">
                                                <div class="font-weight-bold text-white fs-6 mb-1">{{ $order->user->name }}</div>
                                                <div class="text-muted extra-small d-flex align-items-center">
                                                    <i class="far fa-clock mr-2 opacity-70"></i> <span id="time-diff-{{ $order->order_id }}">{{ $lastMessage->created_at->diffForHumans() }}</span>
                                                </div>
                                            </div>
                                        </div>
                                    </td>
                                    <td class="py-4">
                                        <div class="message-preview" id="preview-text-{{ $order->order_id }}">
                                            @if($lastMessage->sender_id == auth()->id())
                                                <span class="text-secondary-light font-weight-bold">Anda: </span>
                                            @endif
                                            {{ $lastMessage->message }}
                                        </div>
                                    </td>
                                    <td class="py-4">
                                        <div class="text-white small font-weight-bold">#ORD-{{ str_pad($order->order_id, 5, '0', STR_PAD_LEFT) }}</div>
                                        <div class="text-muted extra-small">{{ $order->items->count() }} item dipesan</div>
                                    </td>
                                    <td class="py-4" id="status-cell-{{ $order->order_id }}">
                                        <div class="d-flex align-items-center">
                                            <span class="badge badge-aura-status {{ strtolower(str_replace(' ', '-', $order->status->status_name)) }}">
                                                {{ strtoupper($order->status->status_name) }}
                                            </span>
                                            @if($isUnread)
                                                <span class="badge bg-crimson pulse-mini ms-2 unread-badge">NEW</span>
                                            @endif
                                        </div>
                                    </td>

                                    <td class="text-center py-4 rounded-end">
                                        <a href="{{ route('orders.chat', $order->order_id) }}" class="btn btn-primary btn-sm rounded-pill px-4 shadow-crimson-sm hover-scale">
                                            <i class="fas fa-comment-dots mr-2"></i> BUKA CHAT
                                        </a>
                                    </td>
                                </tr>
                            @empty
                                <tr>
                                    <td colspan="5" class="text-center py-5">
                                        <div class="empty-state py-5">
                                            <i class="fas fa-comment-slash mb-4" style="font-size: 4rem; color: rgba(255,255,255,0.05);"></i>
                                            <h4 class="text-muted">Belum ada pesan</h4>
                                            <p class="text-muted small">Pertanyaan pelanggan akan muncul di sini.</p>
                                        </div>
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

@push('js')
<style>
    .inbox-row {
        background: var(--aura-panel);
        border: 1px solid var(--aura-border);
        transition: all 0.4s cubic-bezier(0.165, 0.84, 0.44, 1);
        cursor: pointer;
    }

    .inbox-row:hover {
        background: var(--aura-bg);
        transform: translateY(-2px);
        box-shadow: 0 10px 30px rgba(0,0,0,0.05);
    }

    .unread-thread {
        background: rgba(204, 78, 70, 0.04);
        border-left: 4px solid var(--aura-crimson) !important;
    }

    .avatar-premium {
        width: 45px;
        height: 45px;
        background: rgba(204, 78, 70, 0.1);
        display: flex;
        align-items: center;
        justify-content: center;
        border-radius: 14px;
        font-weight: 800;
        color: var(--aura-crimson);
        font-size: 1.2rem;
    }

    .unread-thread .avatar-premium {
        background: var(--aura-crimson);
        color: white;
        box-shadow: 0 4px 10px rgba(204, 78, 70, 0.2);
    }

    .message-preview {
        color: var(--aura-text-muted);
        font-size: 0.85rem;
        max-width: 350px;
        white-space: nowrap;
        overflow: hidden;
        text-overflow: ellipsis;
        font-style: italic;
    }

    .badge-aura-status {
        padding: 0.5em 1em;
        border-radius: 8px;
        font-size: 0.65rem;
        font-weight: 700;
        letter-spacing: 1px;
        background: rgba(128, 117, 108, 0.15);
        color: var(--aura-text-muted);
    }

    .badge-aura-status.pending { background: rgba(220, 164, 85, 0.15); color: #DCA455; }
    .badge-aura-status.confirmed, .badge-aura-status.delivered { background: rgba(85, 139, 109, 0.15); color: #558B6D; }
    .badge-aura-status.cancelled { background: rgba(204, 78, 70, 0.15); color: var(--aura-crimson); }

    .hover-scale:hover {
        transform: scale(1.05);
    }

    .shadow-crimson-sm {
        box-shadow: 0 4px 15px rgba(255, 51, 75, 0.2);
    }
</style>

<script>
    document.addEventListener('DOMContentLoaded', function() {
        const orderRows = document.querySelectorAll('.inbox-row');
        const orderIds = Array.from(orderRows).map(row => row.id.replace('order-row-', ''));

        const initEchoInbox = () => {
            if (typeof window.Echo === 'undefined') {
                console.warn('Echo is not initialized yet. Retrying...');
                setTimeout(initEchoInbox, 500);
                return;
            }

            console.log('Subscribing to inbox channels for orders:', orderIds);
            orderIds.forEach(orderId => {
                window.Echo.private(`order.${orderId}`)
                    .listen('.message.sent', (data) => {
                        console.log('Inbox update for order ' + orderId + ':', data);
                        
                        const row = document.getElementById(`order-row-${orderId}`);
                        if (!row) return;

                        // 1. Update latest message text
                        const previewDiv = document.getElementById(`preview-text-${orderId}`);
                        if (previewDiv) {
                            const isMe = data.sender_id == {{ auth()->id() }};
                            previewDiv.innerHTML = `
                                ${isMe ? '<span class="text-secondary-light font-weight-bold">Anda: </span>' : ''}
                                ${data.message}
                            `;
                        }

                        // 2. Update time difference
                        const timeSpan = document.getElementById(`time-diff-${orderId}`);
                        if (timeSpan) {
                            timeSpan.textContent = 'Baru saja';
                        }

                        // 3. Mark thread as unread (if message from client)
                        const isMe = data.sender_id == {{ auth()->id() }};
                        if (!isMe) {
                            row.classList.add('unread-thread');
                            
                            // Check if unread badge exists, otherwise create it
                            const statusCell = document.getElementById(`status-cell-${orderId}`);
                            if (statusCell) {
                                const container = statusCell.querySelector('.d-flex');
                                if (container && !container.querySelector('.unread-badge')) {
                                    container.insertAdjacentHTML('beforeend', '<span class="badge bg-crimson pulse-mini ms-2 unread-badge">NEW</span>');
                                }
                            }
                        }

                        // 4. Move row to the top of the table list
                        const tbody = row.closest('tbody');
                        if (tbody) {
                            tbody.prepend(row);
                        }
                    });
            });
        };

        if (orderIds.length > 0) {
            initEchoInbox();
        }
    });
</script>
@endpush

