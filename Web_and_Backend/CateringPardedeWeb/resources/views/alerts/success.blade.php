@if(session($key ?? 'success'))
    <div class="alert alert-success bg-success-light border-0 py-3 mb-5 border-start border-4 border-success">
        <div class="d-flex align-items-center">
            <i class="fas fa-check-double me-3 fs-5"></i>
            <div>
                <div class="fw-bold fs-6">SUCCESS</div>
                <div class="small opacity-75">{{ session($key ?? 'success') }}</div>
            </div>
        </div>
    </div>
@endif
