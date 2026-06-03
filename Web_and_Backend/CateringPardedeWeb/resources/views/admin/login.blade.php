@extends('layouts.app', [
    'class' => 'login-page',
    'page' => __('Login Page'),
    'contentClass' => 'login-page'
])

@section('content')
    <div class="auth-card">
        <div class="text-center mb-5">
            <div class="auth-logo-glow mb-4">
                <i class="fas fa-shield-halved text-danger fs-1"></i>
            </div>
            <h2 class="text-white font-weight-bold mb-1">Login</h2>
            <p class="text-muted small uppercase letter-spacing-1">Welcome</p>
        </div>

        <form class="form" method="POST" action="{{ route('login') }}">
            @csrf

            @if(session('error'))
                <div class="alert alert-danger mb-4 aura-card border-0 text-center animate-pulse" style="background: rgba(255, 77, 77, 0.1); color: #ff4d4d;">
                    <small>{{ session('error') }}</small>
                </div>
            @endif

            <div class="form-group mb-4">
                <label class="text-muted small font-weight-bold mb-2 d-block">EMAIL</label>
                <input 
                    type="email" 
                    name="email" 
                    class="form-control-aura @error('email') is-invalid @enderror" 
                    placeholder="Enter entity email..."
                    value="{{ old('email') }}"
                    autofocus
                >
                @error('email')
                    <span class="invalid-feedback">{{ $message }}</span>
                @enderror
            </div>

            <div class="form-group mb-5">
                <label class="text-muted small font-weight-bold mb-2 d-block">PASSWORD</label>
                <input 
                    type="password" 
                    name="password" 
                    class="form-control-aura @error('password') is-invalid @enderror mb-1" 
                    placeholder="••••••••"
                >
                @error('password')
                    <span class="invalid-feedback">{{ $message }}</span>
                @enderror
            </div>

            <button type="submit" class="btn btn-aura">
                Login
            </button>
        </form>

    </div>
@endsection
