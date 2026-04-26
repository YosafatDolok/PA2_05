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
            <h2 class="text-white font-weight-bold mb-1">Access Protocol</h2>
            <p class="text-muted small uppercase letter-spacing-1">Admin Authorization Required</p>
        </div>

        <form class="form" method="POST" action="{{ route('login') }}">
            @csrf

            <div class="form-group mb-4">
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

            <div class="form-group mb-5">
                <label class="text-muted small font-weight-bold mb-2 d-block">SECRET KEY (PASSWORD)</label>
                <input 
                    type="password" 
                    name="password" 
                    class="form-control-aura mb-1" 
                    placeholder="••••••••"
                    required
                >
                @if (Route::has('password.request'))
                    <div class="text-end">
                        <a href="{{ route('password.request') }}" class="text-danger small text-decoration-none">Reset Key?</a>
                    </div>
                @endif
            </div>

            <button type="submit" class="btn btn-aura">
                Login
            </button>
        </form>

        <div class="mt-5 text-center">
            <p class="text-muted extra-small mb-0">SYST_VER: 2.1.0 // ACTIVE</p>
        </div>
    </div>
@endsection
