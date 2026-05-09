@extends('layouts.app', [
    'class' => 'login-page',
    'page' => __('Activation Success'),
    'contentClass' => 'login-page'
])

@section('content')
    <div class="auth-card text-center">
        <div class="mb-4">
            <div class="auth-logo-glow mb-4 d-inline-block">
                <i class="fas fa-check-circle text-success fs-1"></i>
            </div>
            <h2 class="text-white font-weight-bold mb-1">Account Activated!</h2>
            <p class="text-muted small uppercase letter-spacing-1">Protocol Complete</p>
        </div>

        <div class="my-5 py-3">
            <p class="text-white op-8 fs-5">Selamat! Akun Driver Anda telah berhasil diaktifkan.</p>
            <p class="text-muted small mt-2">Anda sekarang dapat mulai menerima pesanan dan melakukan pengiriman melalui aplikasi mobile.</p>
        </div>

        <div class="aura-card border-0 bg-dark-soft p-4 mb-5">
            <i class="fas fa-mobile-screen-button text-danger mb-3 fs-3"></i>
            <h6 class="text-white mb-2">NEXT STEP:</h6>
            <p class="small text-muted mb-0">Silakan tutup jendela browser ini dan buka <strong>Aplikasi Pardede Driver</strong> di smartphone Anda untuk masuk (Login).</p>
        </div>

        <div class="text-center opacity-50">
            <p class="small text-muted">&copy; {{ date('Y') }} Pardede Catering Operational System</p>
        </div>
    </div>
@endsection
