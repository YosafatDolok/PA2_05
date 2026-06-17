<!DOCTYPE html>
<html lang="{{ str_replace('_', '-', app()->getLocale()) }}">
<head>
    <meta charset="UTF-8">
    <meta http-equiv="X-UA-Compatible" content="ie=edge">
    <meta name="viewport" content="width=device-width, initial-scale=1, shrink-to-fit=no">
    <meta name="csrf-token" content="{{ csrf_token() }}">

    <title>{{ config('app.name', 'Catering Pardede') }} - Admin</title>
    <link rel="icon" type="image/png" href="{{ asset('assets/img/catering_pardede_logo.png') }}">
    <!-- Essential Libraries (CDN for Robustness) -->
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css" rel="stylesheet">
    <link href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css" rel="stylesheet">
    <link href="https://fonts.googleapis.com/css2?family=Outfit:wght@300;400;500;600;700;800&family=Dancing+Script:wght@600;700&display=swap" rel="stylesheet">

    <!-- Aura-Crimson Standalone Design System (Redesigned Light Theme) -->
    <link href="{{ asset('css/crimson-white.css') }}?v={{ time() }}" rel="stylesheet"/>

    @auth
        <meta name="user-id" content="{{ auth()->id() }}">
    @endauth

    @vite(['resources/css/app.css', 'resources/js/app.js'])


</head>

<body class="{{ $class ?? '' }}">

@auth()
    <div class="aura-app">
        @include('layouts.navbars.sidebar')

        <main class="aura-main-panel">
            <header class="aura-navbar d-flex align-items-center justify-content-between">
                <div class="nav-brand-group d-flex align-items-center">
                    <button class="btn aura-menu-toggle d-lg-none me-3">
                        <i class="fas fa-bars text-white"></i>
                    </button>
                    <h5 class="m-0 text-white font-weight-bold">{{ $page ?? 'Dashboard' }}</h5>
                </div>

                <div class="nav-utils d-flex align-items-center">
                    @include('layouts.navbars.navs.auth')
                </div>
            </header>

            <section class="aura-content">
                <div class="container-fluid p-0">
                    @yield('content')
                </div>
            </section>

            <footer class="aura-footer text-center py-4 mt-auto">
                <p class="text-muted small mb-0">Catering Pardede</p>
            </footer>
        </main>
    </div>

    <form id="logout-form" action="{{ route('logout') }}" method="POST" style="display: none;">
        @csrf
    </form>
@else
    <div class="aura-auth-page">
        @yield('content')
    </div>
@endauth

{{-- ================= SCRIPTS ================= --}}
<script src="https://code.jquery.com/jquery-3.6.0.min.js"></script>
<script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/js/bootstrap.bundle.min.js"></script>
<script src="https://cdn.jsdelivr.net/npm/sweetalert2@11"></script>

<!-- ApexCharts -->
<script src="https://cdn.jsdelivr.net/npm/apexcharts"></script>

<!-- Aura-Crimson Core JS -->
<script src="{{ asset('js/aura-crimson.js') }}"></script>

@stack('js')



</body>
</html>
