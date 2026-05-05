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
                        <h3 class="stat-value {{ $revenueGrowth >= 0 ? 'text-success' : 'text-danger' }}">
                            {{ $revenueGrowth >= 0 ? '+' : '' }}{{ $revenueGrowth }}%
                        </h3>
                    </div>
                </div>
            </div>
        </div>
    </div>

    {{-- Charts Row --}}
    <div class="row g-4 mb-5">
        {{-- Revenue Growth Area Chart --}}
        <div class="col-xl-8">
            <div class="aura-card h-100">
                <div class="d-flex justify-content-between align-items-center mb-4">
                    <h5 class="m-0 text-white font-weight-bold">Revenue Growth</h5>
                    <span class="badge bg-crimson pulse-mini">Real-time</span>
                </div>
                <div id="revenueChart" style="min-height: 350px;"></div>
            </div>
        </div>

        {{-- Order Status Donut Chart --}}
        <div class="col-xl-4">
            <div class="aura-card h-100">
                <h5 class="mb-4 text-white font-weight-bold">Order Distribution</h5>
                <div id="statusChart" style="min-height: 350px;"></div>
            </div>
        </div>
    </div>

    {{-- Top Menus Row --}}
    <div class="row g-4 mb-5">
        <div class="col-12">
            <div class="aura-card">
                <h5 class="mb-4 text-white font-weight-bold">Top Performing Menus</h5>
                <div id="menuChart" style="min-height: 300px;"></div>
            </div>
        </div>
    </div>

@endsection

@push('js')
<script>
    // Global ApexCharts Defaults for Aura-Crimson Theme
    window.Apex = {
        chart: {
            foreColor: '#94a3b8',
            toolbar: { show: false },
        },
        grid: {
            borderColor: 'rgba(255,255,255,0.05)',
        },
        stroke: {
            curve: 'smooth',
            width: 3,
        },
        tooltip: {
            theme: 'dark',
        }
    };

    // 1. Revenue Chart
    const revenueOptions = {
        series: [{
            name: 'Revenue',
            data: {!! json_encode($revenueData->pluck('total')) !!}
        }],
        chart: {
            type: 'area',
            height: 350,
            animations: {
                enabled: true,
                easing: 'easeinout',
                speed: 800,
            }
        },
        colors: ['#ff334b'],
        fill: {
            type: 'gradient',
            gradient: {
                shadeIntensity: 1,
                opacityFrom: 0.4,
                opacityTo: 0,
                stops: [0, 90, 100]
            }
        },
        xaxis: {
            categories: {!! json_encode($revenueData->pluck('month')) !!},
        },
        yaxis: {
            labels: {
                formatter: function (value) {
                    return "Rp " + value.toLocaleString();
                }
            }
        },
    };

    // 2. Status Distribution Chart
    const statusOptions = {
        series: {!! json_encode($statusDistribution->pluck('count')) !!},
        chart: {
            type: 'donut',
            height: 350,
        },
        labels: {!! json_encode($statusDistribution->pluck('label')) !!},
        colors: ['#ff334b', '#4cd137', '#00a8ff', '#fbc531', '#9c88ff'],
        stroke: {
            show: false,
        },
        legend: {
            position: 'bottom'
        },
        plotOptions: {
            pie: {
                donut: {
                    size: '70%',
                    labels: {
                        show: true,
                        total: {
                            show: true,
                            label: 'Orders',
                            color: '#fff',
                        }
                    }
                }
            }
        }
    };

    // 3. Top Menus Chart
    const menuOptions = {
        series: [{
            name: 'Orders',
            data: {!! json_encode($topMenus->pluck('count')) !!}
        }],
        chart: {
            type: 'bar',
            height: 300,
        },
        colors: ['#fbc531'],
        plotOptions: {
            bar: {
                borderRadius: 8,
                horizontal: true,
                barHeight: '60%',
            }
        },
        xaxis: {
            categories: {!! json_encode($topMenus->pluck('name')) !!},
        },
    };

    // Render All Charts
    new ApexCharts(document.querySelector("#revenueChart"), revenueOptions).render();
    new ApexCharts(document.querySelector("#statusChart"), statusOptions).render();
    new ApexCharts(document.querySelector("#menuChart"), menuOptions).render();
</script>
@endpush
