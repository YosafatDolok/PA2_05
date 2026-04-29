@extends('layouts.app', [
    'class' => 'login-page',
    'page' => __('Reset Password'),
    'contentClass' => 'login-page'
])

@section('content')
    <div class="auth-card">
        <div class="text-center mb-5">
            <div class="auth-logo-glow mb-4">
                <i class="fas fa-lock-open text-danger fs-1"></i>
            </div>
            <h2 class="text-white font-weight-bold mb-1">Finalizing Reset</h2>
            <p class="text-muted small uppercase letter-spacing-1">Authentication Required</p>
        </div>

        @if ($errors->any())
            <div class="alert alert-danger bg-danger-soft text-danger border-0 mb-4 small">
                @foreach ($errors->all() as $error)
                    <div>{{ $error }}</div>
                @endforeach
            </div>
        @endif

        <form class="form" method="POST" action="{{ route('admin.password.update') }}">
            @csrf

            <input type="hidden" name="email" value="{{ $email }}">

            <div class="form-group mb-4">
                <label class="text-muted small font-weight-bold mb-2 d-block">6-DIGIT OTP CODE</label>
                <input 
                    type="text" 
                    name="otp" 
                    class="form-control-aura text-center fs-4 letter-spacing-4" 
                    placeholder="000000"
                    maxlength="6"
                    required
                    autofocus
                >
            </div>

            <div class="form-group mb-4">
                <label class="text-muted small font-weight-bold mb-2 d-block">NEW SECRET KEY</label>
                <input 
                    type="password" 
                    name="password" 
                    class="form-control-aura" 
                    placeholder="••••••••"
                    required
                >
            </div>

            <div class="form-group mb-5">
                <label class="text-muted small font-weight-bold mb-2 d-block">CONFIRM SECRET KEY</label>
                <input 
                    type="password" 
                    name="password_confirmation" 
                    class="form-control-aura" 
                    placeholder="••••••••"
                    required
                >
            </div>

            <button type="submit" class="btn btn-aura">
                REINITIALIZE PASSWORD
            </button>
        </form>
    </div>
@endsection
