@extends('layouts.app', [
    'class' => 'login-page',
    'page' => __('Reset Password'),
    'contentClass' => 'login-page'
])

@section('content')
    <div class="auth-card">
        <div class="text-center mb-5">
            <div class="auth-logo-glow mb-4">
                <i class="fas fa-key text-danger fs-1"></i>
            </div>
            <h2 class="text-white font-weight-bold mb-1">Recovery Protocol</h2>
            <p class="text-muted small uppercase letter-spacing-1">Initiating Password Reset</p>
        </div>

        @if (session('status'))
            <div class="alert alert-success bg-danger-soft text-danger border-0 mb-4 small">
                {{ session('status') }}
            </div>
        @endif

        @if ($errors->any())
            <div class="alert alert-danger bg-danger-soft text-danger border-0 mb-4 small">
                @foreach ($errors->all() as $error)
                    <div>{{ $error }}</div>
                @endforeach
            </div>
        @endif

        <form class="form" method="POST" action="{{ route('admin.password.email') }}">
            @csrf

            <div class="form-group mb-5">
                <label class="text-muted small font-weight-bold mb-2 d-block">ID ENTITY (EMAIL)</label>
                <input 
                    type="email" 
                    name="email" 
                    class="form-control-aura" 
                    placeholder="Enter entity email..."
                    value="{{ old('email') }}"
                    required
                    autofocus
                >
            </div>

            <button type="submit" class="btn btn-aura">
                SEND OTP CODE
            </button>
            
            <div class="text-center mt-4">
                <a href="{{ route('login') }}" class="text-muted small text-decoration-none">
                    <i class="fas fa-arrow-left me-1"></i> Abort & Return to Login
                </a>
            </div>
        </form>
    </div>
@endsection
