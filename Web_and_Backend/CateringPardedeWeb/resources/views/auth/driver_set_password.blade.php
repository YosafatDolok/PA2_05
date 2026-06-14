@extends('layouts.guest', ['title' => 'Activate Account'])

@section('content')
    <div class="auth-card">
        <div class="text-center mb-5">
            <div class="auth-logo-glow mb-4">
                <i class="fas fa-id-card text-danger fs-1"></i>
            </div>
            <h2 class="text-white font-weight-bold mb-1">Activate Account</h2>
            <p class="text-muted small uppercase letter-spacing-1">Welcome to Pardede Catering, {{ $user->name }}</p>
        </div>

        <form class="form" method="POST" action="{{ route('driver.invite.setPassword', $token) }}">
            @csrf

            <div class="form-group mb-4">
                <label class="text-muted small font-weight-bold mb-2 d-block">NEW PASSWORD</label>
                <input 
                    type="password" 
                    name="password" 
                    class="form-control-aura @error('password') is-invalid @enderror" 
                    placeholder="Min. 8 characters"
                    required
                >
                @error('password')
                    <span class="invalid-feedback">{{ $message }}</span>
                @enderror
            </div>

            <div class="form-group mb-5">
                <label class="text-muted small font-weight-bold mb-2 d-block">CONFIRM PASSWORD</label>
                <input 
                    type="password" 
                    name="password_confirmation" 
                    class="form-control-aura" 
                    placeholder="Repeat password"
                    required
                >
            </div>

            <button type="submit" class="btn btn-aura">
                ACTIVATE MY ACCOUNT
            </button>
        </form>

    </div>
@endsection
