@extends('layouts.app', ['page' => __('Dashboard')])

@section('content')
    <div class="row g-4 mb-5">
        {{-- Stat Card 1 --}}
        <div class="col-xl-3 col-md-6">
            <div class="aura-card mb-0 h-100">
                <div class="stat-card">
                    <div class="stat-icon bg-aura-crimson-soft text-aura-crimson">
                        <i class="fas fa-utensils"></i>
                    </div>
                    <div>
                        <p class="stat-label">Total Menu</p>
                        <h3 class="stat-value">{{ $totalMenus ?? 0 }}</h3>
                    </div>
                </div>
            </div>
        </div>

        {{-- Stat Card 2 --}}
        <div class="col-xl-3 col-md-6">
            <div class="aura-card mb-0 h-100">
                <div class="stat-card">
                    <div class="stat-icon" style="background: rgba(85, 139, 109, 0.08); color: #558B6D;">
                        <i class="fas fa-cart-shopping"></i>
                    </div>
                    <div>
                        <p class="stat-label">Pesanan Masuk</p>
                        <h3 class="stat-value">{{ $ordersReceived ?? 0 }}</h3>
                    </div>
                </div>
            </div>
        </div>

        {{-- Stat Card 3 --}}
        <div class="col-xl-3 col-md-6">
            <div class="aura-card mb-0 h-100">
                <div class="stat-card">
                    <div class="stat-icon bg-warning-transparent">
                        <i class="fas fa-bowl-food"></i>
                    </div>
                    <div>
                        <p class="stat-label">Menu Aktif</p>
                        <h3 class="stat-value">{{ $activeMenus ?? 0 }}</h3>
                    </div>
                </div>
            </div>
        </div>

        {{-- Stat Card 4 --}}
        <div class="col-xl-3 col-md-6">
            <div class="aura-card mb-0 h-100">
                <div class="stat-card">
                    <div class="stat-icon" style="background: rgba(69, 140, 150, 0.08); color: #458C96;">
                        <i class="fas fa-chart-line"></i>
                    </div>
                    <div>
                        <p class="stat-label">Pertumbuhan Pendapatan</p>
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
                    <h5 class="m-0 text-white font-weight-bold">Pertumbuhan Pendapatan</h5>
                    <select id="revenueFilter" class="form-control text-white border-secondary bg-dark" style="width: auto; display: inline-block; cursor: pointer; padding: 2px 10px; height: auto;" onchange="location.href='?filter='+this.value">
                        <option value="weekly" {{ request('filter') == 'weekly' ? 'selected' : '' }}>Mingguan</option>
                        <option value="monthly" {{ request('filter') == 'monthly' || !request('filter') ? 'selected' : '' }}>Bulanan</option>
                        <option value="yearly" {{ request('filter') == 'yearly' ? 'selected' : '' }}>Tahunan</option>
                    </select>
                </div>
                <div id="revenueChart" style="min-height: 350px;"></div>
            </div>
        </div>

        {{-- Order Status Donut Chart --}}
        <div class="col-xl-4">
            <div class="aura-card h-100">
                <h5 class="mb-4 text-white font-weight-bold">Distribusi Pesanan</h5>
                <div id="statusChart" style="min-height: 350px;"></div>
            </div>
        </div>
    </div>

    {{-- Top Menus Row --}}
    <div class="row g-4 mb-5">
        <div class="col-12">
            <div class="aura-card">
                <h5 class="mb-4 text-white font-weight-bold">Menu Terlaris</h5>
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
            foreColor: '#5C544E',
            toolbar: { show: false },
        },
        grid: {
            borderColor: '#F0EAE1',
        },
        stroke: {
            curve: 'smooth',
            width: 3,
        },
        tooltip: {
            theme: 'light',
        }
    };

    // 1. Revenue Chart
    const revenueOptions = {
        series: [{
            name: 'Pendapatan',
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
        colors: ['#CC4E46'],
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
        colors: ['#CC4E46', '#558B6D', '#DCA455', '#E29578', '#458C96', '#82a3a1'],
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
                            label: 'Pesanan',
                            color: '#2C2825',
                        }
                    }
                }
            }
        }
    };

    // 3. Top Menus Chart
    const menuOptions = {
        series: [{
            name: 'Pesanan',
            data: {!! json_encode($topMenus->pluck('count')) !!}
        }],
        chart: {
            type: 'bar',
            height: 300,
        },
        colors: ['#DCA455'],
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
