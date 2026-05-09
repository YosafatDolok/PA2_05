@if(session($key ?? 'error'))
    <div class="alert alert-danger bg-danger-light border-0 py-3 mb-5 border-start border-4 border-danger">
        <div class="d-flex align-items-center">
            <i class="fas fa-exclamation-triangle me-3 fs-5"></i>
            <div>
                <div class="fw-bold fs-6">ERROR</div>
                <div class="small opacity-75">{{ session($key ?? 'error') }}</div>
            </div>
        </div>
    </div>
@endif
