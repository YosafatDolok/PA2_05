@extends('layouts.guest', ['title' => '403 - Akses Ditolak'])

@section('content')
<div class="auth-card text-center">

    <div class="mb-4">
        <div class="auth-logo-glow mb-4 d-inline-block">
            <i class="fas fa-shield-halved text-danger" style="font-size: 3rem;"></i>
        </div>
        <h2 class="font-weight-bold mb-1" style="color: #2D0A0A; font-size: 2rem;">403</h2>
        <p class="small font-weight-bold letter-spacing-1" style="color: #B8860B; text-transform: uppercase; letter-spacing: 2px;">Akses Ditolak</p>
    </div>

    <div class="my-4">
        <p style="color: #555; font-size: 1rem; line-height: 1.6;">
            Anda tidak memiliki izin untuk mengakses halaman ini.<br>
            Halaman ini hanya tersedia untuk administrator sistem.
        </p>
    </div>

    <div class="aura-card border-0 p-4 mb-5" style="background: #fff5f5; border-radius: 16px;">
        <i class="fas fa-mobile-screen-button text-danger mb-3" style="font-size: 1.5rem;"></i>
        <p class="small mb-0" style="color: #666;">
            Jika Anda adalah <strong>Driver</strong>, silakan gunakan
            <strong>Aplikasi Pardede Driver</strong> di smartphone Anda untuk masuk.
        </p>
    </div>

    <div class="text-center opacity-50">
        <p class="small" style="color: #999;">&copy; {{ date('Y') }} Catering Pardede Operational System</p>
    </div>
</div>
@endsection
