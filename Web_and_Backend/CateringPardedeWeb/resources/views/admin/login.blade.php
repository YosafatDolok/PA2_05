@extends('layouts.app', [
    'class' => 'login-page',
    'page' => __('Login Page'),
    'contentClass' => 'login-page'
])

@section('content')
    <div class="col-md-10 text-center ml-auto mr-auto">
        <h3 class="mb-5">
            Log in to your admin panel
        </h3>
    </div>

    <div class="col-lg-4 col-md-6 ml-auto mr-auto">
        <form class="form" method="POST" action="{{ route('login') }}">
            @csrf

            <div class="card card-login card-white">
                <div class="card-header">
                    <img src="{{ asset('black/img/card-primary.png') }}" alt="">
                    <h1 class="card-title">{{ __('Log in') }}</h1>
                </div>

                <div class="card-body">

                    {{-- SESSION ERROR (from your old page) --}}
                    @if(session('error'))
                        <p class="text-danger text-center">{{ session('error') }}</p>
                    @endif

                    {{-- EMAIL --}}
                    <div class="input-group{{ $errors->has('email') ? ' has-danger' : '' }}">
                        <div class="input-group-prepend">
                            <div class="input-group-text" style="padding-left: 8px; padding-right: 8px;">
                                <i class="tim-icons icon-email-85" ></i>
                            </div>
                        </div>
                        <input 
                            type="email" 
                            name="email" 
                            class="form-control{{ $errors->has('email') ? ' is-invalid' : '' }}" 
                            placeholder="{{ __('Email') }}"
                            value="{{ old('email') }}"
                        >
                        @if($errors->has('email'))
                            <div class="invalid-feedback d-block">
                                {{ $errors->first('email') }}
                            </div>
                        @endif
                    </div>

                    {{-- PASSWORD --}}
                    <div class="input-group{{ $errors->has('password') ? ' has-danger' : '' }}">
                        <div class="input-group-prepend">
                            <div class="input-group-text" style="padding-left: 8px; padding-right: 8px;">
                                <i class="tim-icons icon-lock-circle"></i>
                            </div>
                        </div>
                        <input 
                            type="password" 
                            name="password" 
                            class="form-control{{ $errors->has('password') ? ' is-invalid' : '' }}" 
                            placeholder="{{ __('Password') }}"
                        >
                        @if($errors->has('password'))
                            <div class="invalid-feedback d-block">
                                {{ $errors->first('password') }}
                            </div>
                        @endif
                    </div>

                </div>

                <div class="card-footer">
                    <button type="submit" class="btn btn-primary btn-lg btn-block mb-3">
                        {{ __('Get Started') }}
                    </button>

                </div>

            </div>
        </form>
    </div>
@endsection