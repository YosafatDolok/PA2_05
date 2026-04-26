@extends('layouts.app', ['page' => __('Dashboard')])

@section('content')
    <div class="row g-4 mb-5">
        {{-- Stat Card 1 --}}
        <div class="col-xl-3 col-md-6">
            <div class="aura-card mb-0 h-100">
                <div class="stat-card">
                    <div class="stat-icon">
                        <i class="fas fa-utensils"></i>
                    </div>
                    <div>
                        <p class="stat-label">Total Menus</p>
                        <h3 class="stat-value">{{ $totalMenus ?? 0 }}</h3>
                    </div>
                </div>
            </div>
        </div>

        {{-- Stat Card 2 --}}
        <div class="col-xl-3 col-md-6">
            <div class="aura-card mb-0 h-100">
                <div class="stat-card">
                    <div class="stat-icon" style="color: #4cd137;">
                        <i class="fas fa-cart-shopping"></i>
                    </div>
                    <div>
                        <p class="stat-label">Orders Received</p>
                        <h3 class="stat-value">{{ $ordersReceived ?? 0 }}</h3>
                    </div>
                </div>
            </div>
        </div>

        {{-- Stat Card 3 --}}
        <div class="col-xl-3 col-md-6">
            <div class="aura-card mb-0 h-100">
                <div class="stat-card">
                    <div class="stat-icon" style="color: #00a8ff;">
                        <i class="fas fa-bowl-food"></i>
                    </div>
                    <div>
                        <p class="stat-label">Active Menus</p>
                        <h3 class="stat-value">{{ $activeMenus ?? 0 }}</h3>
                    </div>
                </div>
            </div>
        </div>

        {{-- Stat Card 4 --}}
        <div class="col-xl-3 col-md-6">
            <div class="aura-card mb-0 h-100">
                <div class="stat-card">
                    <div class="stat-icon" style="color: #fbc531;">
                        <i class="fas fa-chart-line"></i>
                    </div>
                    <div>
                        <p class="stat-label">Revenue Growth</p>
                        <h3 class="stat-value">+24%</h3>
                    </div>
                </div>
            </div>
        </div>
    </div>

@endsection
