@if(session($key ?? 'status'))
    <div class="alert alert-info bg-aura-crimson-soft border-0 py-3 mb-5 border-start border-4 border-aura-crimson">
        <div class="d-flex align-items-center">
            <i class="fas fa-info-circle me-3 fs-5 text-aura-crimson"></i>
            <div>
                <div class="fw-bold fs-6 text-aura-crimson">STATUS</div>
                <div class="small text-white op-8">{{ session($key ?? 'status') }}</div>
            </div>
        </div>
    </div>
@endif
