@extends('layouts.app', [
    'page' => __('Negotiation Chat'),
    'pageSlug' => 'orders'
])

@section('content')
<div class="row h-100">
    <!-- Left Side: Order Summary -->
    <div class="col-md-4">
        <div class="card aura-card border-0 shadow-lg p-4 mb-4">
            <div class="d-flex align-items-center mb-4">
                <a href="{{ route('orders.show', $order->order_id) }}" class="btn btn-link text-secondary p-0 mr-3">
                    <i class="fas fa-chevron-left"></i>
                </a>
                <h4 class="font-weight-bold m-0">Order Summary</h4>
            </div>

            <div class="mb-4">
                <label class="text-muted extra-small uppercase d-block">Customer</label>
                <div class="d-flex align-items-center mt-2">
                    <div class="avatar-circle mr-3" style="width: 40px; height: 40px; background: var(--aura-crimson); display: flex; align-items: center; justify-content: center; border-radius: 50%; font-weight: bold; color: white;">
                        {{ substr($order->user->name, 0, 1) }}
                    </div>
                    <div>
                        <p class="m-0 font-weight-bold">{{ $order->user->name }}</p>
                        <p class="m-0 text-muted small">ID: #USR-{{ $order->user->user_id }}</p>
                    </div>
                </div>
            </div>

            <div class="mb-4">
                <label class="text-muted extra-small uppercase d-block">Status & Price</label>
                <div class="mt-2">
                    <span class="badge bg-primary-light mb-2">{{ strtoupper($order->status->status_name) }}</span>
                    <h3 class="text-secondary font-weight-bold" id="current-final-price">Rp {{ number_format($order->final_price ?? 0, 0, ',', '.') }}</h3>
                </div>
            </div>

            <div class="mb-4">
                <label class="text-muted extra-small uppercase d-block">Items</label>
                <ul class="list-unstyled mt-2">
                    @foreach($order->items as $item)
                        <li class="text-white mb-2">• {{ $item->menu->name }}</li>
                    @endforeach
                </ul>
            </div>

            {{-- <hr class="border-secondary opacity-20">
            <div class="mt-4">
                <h5 class="font-weight-bold text-secondary mb-3">Quick Actions</h5>
                <button type="button" class="btn btn-primary w-100 rounded-pill mb-2" data-bs-toggle="modal" data-bs-target="#proposalModal">
                    <i class="fas fa-file-invoice-dollar mr-2"></i> SEND NEW PROPOSAL
                </button>
            </div> --}}
        </div>
    </div>

    <!-- Right Side: Chat Window -->
    <div class="col-md-8">
        <div class="card aura-card border-0 shadow-lg d-flex flex-column" style="height: 75vh;">
            <div class="card-header border-bottom border-secondary p-3">
                <h5 class="m-0 font-weight-bold text-white">{{ $order->user->name }}</h5>
            </div>
            
            <div id="chat-messages" class="card-body overflow-auto p-4 d-flex flex-column">
                <!-- Messages will be injected here -->
                <div class="text-center py-5" id="chat-loader">
                    <div class="spinner-border text-secondary" role="status"></div>
                </div>
            </div>

            <div class="card-footer border-top border-secondary p-3 bg-dark-aura">
                <form id="chat-form" class="d-flex align-items-center" style="gap: 15px;">
                    <div class="flex-grow-1">
                        <input type="text" id="message-input" class="form-control bg-dark border-secondary text-white rounded-pill px-4 w-100" style="height: 50px;" placeholder="Type your response..." autocomplete="off">
                    </div>
                    <button type="submit" class="btn btn-primary btn-icon rounded-circle shadow-aura flex-shrink-0" style="width: 50px; height: 50px; padding: 0; display: flex; align-items: center; justify-content: center;">
                        <i class="fas fa-paper-plane"></i>
                    </button>
                </form>
            </div>
        </div>
    </div>
</div>

<!-- Proposal Modal -->
<div class="modal fade" id="proposalModal" tabindex="-1">
    <div class="modal-dialog modal-dialog-centered">
        <div class="modal-content aura-card border-0">
            <div class="modal-header border-bottom border-secondary">
                <h5 class="modal-title font-weight-bold">Send Price Proposal</h5>
                <button type="button" class="btn-close btn-close-white" data-bs-dismiss="modal"></button>
            </div>
            <form id="proposal-form">
                <div class="modal-body p-4">
                    <div class="mb-4">
                        <label class="text-muted small uppercase mb-2 d-block">Proposed Price (Rp)</label>
                        <input type="number" id="proposal-price" class="form-control bg-dark border-secondary text-white" placeholder="e.g. 5000000" required>
                    </div>
                    <div class="mb-2">
                        <label class="text-muted small uppercase mb-2 d-block">Note / Reason</label>
                        <textarea id="proposal-message" class="form-control bg-dark border-secondary text-white" rows="3" placeholder="Explain the price breakdown..."></textarea>
                    </div>
                </div>
                <div class="modal-footer border-top border-secondary">
                    <button type="button" class="btn btn-link text-muted" data-bs-dismiss="modal">Cancel</button>
                    <button type="submit" class="btn btn-primary rounded-pill px-4">SEND PROPOSAL</button>
                </div>
            </form>
        </div>
    </div>
</div>

@endsection

@push('js')
<script>
    const orderId = {{ $order->order_id }};
    const currentUserId = {{ auth()->id() }};
    const chatContainer = document.getElementById('chat-messages');
    const chatForm = document.getElementById('chat-form');
    const proposalForm = document.getElementById('proposal-form');
    const messageInput = document.getElementById('message-input');

    // Initialize Echo Subscription
    const initEchoChat = () => {
        if (typeof window.Echo === 'undefined') {
            console.warn('Echo is not initialized yet. Retrying...');
            setTimeout(initEchoChat, 500);
            return;
        }

        console.log('Subscribing to order channel via Echo:', orderId);
        window.Echo.private(`order.${orderId}`)
            .listen('.message.sent', (data) => {
                appendMessage(data);
                scrollToBottom();
                
                if (data.type === 'proposal' && data.proposal_status === 'accepted') {
                    const priceEl = document.getElementById('current-final-price');
                    if (priceEl) {
                        priceEl.innerText = `Rp ${new Intl.NumberFormat('id-ID').format(data.proposed_price)}`;
                    }
                }
            });
    };

    initEchoChat();

    // Load initial messages
    fetch(`/api/orders/${orderId}/messages`, {
        headers: {
            'Accept': 'application/json',
            'X-Requested-With': 'XMLHttpRequest'
        }
    })
    .then(r => r.json())
    .then(messages => {
        const loader = document.getElementById('chat-loader');
        if (loader) loader.remove();
        messages.forEach(appendMessage);
        scrollToBottom();
    });


    // Send Message
    chatForm.addEventListener('submit', (e) => {
        e.preventDefault();
        const text = messageInput.value.trim();
        if (!text) return;

        sendMessage({ message: text });
        messageInput.value = '';
    });

    // Send Proposal
    proposalForm.addEventListener('submit', (e) => {
        e.preventDefault();
        const price = document.getElementById('proposal-price').value;
        const message = document.getElementById('proposal-message').value;

        sendMessage({ 
            message: message, 
            type: 'proposal', 
            proposed_price: price 
        });

        bootstrap.Modal.getInstance(document.getElementById('proposalModal')).hide();
        proposalForm.reset();
    });

    function sendMessage(payload) {
        fetch(`/api/orders/${orderId}/messages`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
                'X-CSRF-TOKEN': '{{ csrf_token() }}',
                'Accept': 'application/json'
            },
            body: JSON.stringify(payload)
        })
        .then(r => r.json())
        .then(appendMessage)
        .then(scrollToBottom);
    }

    function appendMessage(msg) {
        // Prevent duplicate if broadcast arrives after POST response
        if (document.getElementById(`msg-${msg.message_id}`)) return;

        const isMe = msg.sender_id == currentUserId;
        const div = document.createElement('div');
        div.id = `msg-${msg.message_id}`;
        div.className = `message-bubble-wrapper d-flex ${isMe ? 'justify-content-end' : 'justify-content-start'} mb-3`;
        
        let contentHtml = '';
        if (msg.type === 'proposal') {
            contentHtml = `
                <div class="proposal-bubble p-3 rounded shadow-sm text-center" style="background: rgba(255, 193, 7, 0.1); border: 2px solid #ffc107; max-width: 80%;">
                    <i class="fas fa-file-invoice-dollar text-warning mb-2" style="font-size: 1.5rem;"></i>
                    <p class="small font-weight-bold text-warning uppercase m-0">PRICE PROPOSAL</p>
                    <h4 class="font-weight-bold text-white my-2">Rp ${new Intl.NumberFormat('id-ID').format(msg.proposed_price)}</h4>
                    <p class="small text-muted mb-3 italic">"${msg.message}"</p>
                    <span class="badge ${msg.proposal_status === 'accepted' ? 'bg-success' : (msg.proposal_status === 'declined' ? 'bg-danger' : 'bg-warning')} small px-3">
                        ${(msg.proposal_status || 'PENDING').toUpperCase()}
                    </span>
                </div>
            `;
        } else {
            contentHtml = `
                <div class="message-bubble p-3 rounded shadow-sm" style="background: ${isMe ? 'var(--aura-crimson)' : 'rgba(255,255,255,0.05)'}; max-width: 70%;">
                    <p class="m-0 text-white">${msg.message}</p>
                    <div class="text-right mt-1">
                        <small class="text-white-50" style="font-size: 0.65rem;">${new Date(msg.created_at).toLocaleTimeString([], {hour: '2-digit', minute:'2-digit'})}</small>
                    </div>
                </div>
            `;
        }

        div.innerHTML = contentHtml;
        chatContainer.appendChild(div);
    }

    function scrollToBottom() {
        chatContainer.scrollTop = chatContainer.scrollHeight;
    }
</script>

<style>
    #chat-messages {
        flex: 1;
        scrollbar-width: thin;
        scrollbar-color: rgba(255,255,255,0.1) transparent;
    }
    #chat-messages::-webkit-scrollbar { width: 6px; }
    #chat-messages::-webkit-scrollbar-track { background: transparent; }
    #chat-messages::-webkit-scrollbar-thumb { background: rgba(255,255,255,0.1); border-radius: 10px; }
    #chat-messages::-webkit-scrollbar-thumb:hover { background: rgba(255,255,255,0.2); }
    
    .status-dot {
        width: 10px;
        height: 10px;
        border-radius: 50%;
        background: #4caf50;
        box-shadow: 0 0 10px #4caf50;
    }
    
    .bg-dark-aura { background: rgba(0,0,0,0.2); }
    .shadow-aura { box-shadow: 0 0 15px rgba(255, 51, 75, 0.4); }
    
    .message-bubble {
        position: relative;
        word-break: break-word;
    }
    
    .avatar-circle {
        flex-shrink: 0;
    }
</style>
@endpush
