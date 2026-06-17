@extends('layouts.app', [
    'page' => __('Lokasi Pesanan'),
    'pageSlug' => 'logistics'
])

@section('content')
    <link rel="stylesheet" href="https://unpkg.com/leaflet@1.9.4/dist/leaflet.css" />
    <link rel="stylesheet" href="https://unpkg.com/leaflet-routing-machine@latest/dist/leaflet-routing-machine.css" />
    
    <div class="d-flex justify-content-between align-items-center mb-4">
        <div>
            <h2 class="m-0 font-weight-bold text-white">Lokasi Pesanan</h2>
            <p class="text-muted small uppercase letter-spacing-1 mb-0">Destinasi Sopir</p>
        </div>
        <div class="d-flex gap-2">
        </div>
    </div>

    <div class="row g-4">
        {{-- Map Column --}}
        <div class="col-xl-9 col-lg-8">
            <div class="aura-card border-0 shadow-lg p-0 overflow-hidden" style="height: 650px;">
                <div id="logisticsMap" style="height: 100%; width: 100%; background: #1a1a1a;"></div>
            </div>
        </div>

        {{-- Drivers Info Column --}}
        <div class="col-xl-3 col-lg-4">
            <div class="aura-card border-0 shadow-lg p-4 h-100 overflow-auto" style="max-height: 650px;">
                <h5 class="text-secondary font-weight-bold mb-4 border-bottom border-secondary pb-2">Sopir Aktif</h5>
                
                @forelse($drivers as $driver)
                <div class="driver-status-card mb-3 p-3 rounded" style="background: rgba(255,255,255,0.03);">
                    <div class="d-flex align-items-center mb-2">
                        <div class="driver-avatar me-3" style="width: 40px; height: 40px; border-radius: 50%; background: #ff334b; display: flex; align-items:center; justify-content:center;">
                            <i class="fas fa-truck text-white"></i>
                        </div>
                        <div>
                            <h6 class="m-0 text-white font-weight-bold">{{ $driver->name }}</h6>
                        </div>
                    </div>

                </div>
                @empty
                <div class="text-center py-5">
                    <p class="text-muted italic">Belum ada sopir terdaftar</p>
                </div>
                @endforelse

                <h5 class="text-secondary font-weight-bold mb-4 mt-5 border-bottom border-secondary pb-2">Pengiriman Aktif</h5>
                @forelse($activeOrders as $order)
                <div class="order-status-card mb-3 p-3 rounded" style="background: rgba(255,255,255,0.03); border-left: 3px solid #00a8ff;">
                    <div class="d-flex justify-content-between align-items-start">
                        <h6 class="m-0 text-white font-weight-bold">ORD-{{ str_pad($order->order_id, 5, '0', STR_PAD_LEFT) }}</h6>
                        @if($order->total_payable > $order->total_paid)
                            <span class="badge bg-warning extra-small" title="Ada tagihan tambahan belum dibayar!">BELUM LUNAS</span>
                        @endif
                    </div>
                    <p class="small text-muted mb-2">{{ \Illuminate\Support\Str::limit($order->event_address, 40) }}</p>
                    <span class="badge bg-primary-light extra-small">{{ strtoupper($order->status->status_name) }}</span>
                </div>
                @empty
                <div class="text-center py-5">
                    <p class="text-muted italic">Belum ada pengiriman aktif</p>
                </div>
                @endforelse
            </div>
        </div>
    </div>
@endsection

@push('js')
<script src="https://unpkg.com/leaflet@1.9.4/dist/leaflet.js"></script>
<script src="https://unpkg.com/leaflet-routing-machine@latest/dist/leaflet-routing-machine.js"></script>
<script>
    document.addEventListener('DOMContentLoaded', function() {
        // Initialize Map centered on Pardede Base
        const map = L.map('logisticsMap', {
            zoomControl: false
        }).setView([{{ $baseLocation['lat'] }}, {{ $baseLocation['lng'] }}], 13);

        L.tileLayer('https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png', {
            attribution: '&copy; CartoDB'
        }).addTo(map);

        L.control.zoom({ position: 'bottomright' }).addTo(map);

        // Custom Icons
        const baseIcon = L.divIcon({
            className: 'custom-div-icon',
            html: "<div style='background-color:#ffd700; width:35px; height:35px; border-radius:50%; border:3px solid white; box-shadow:0 0 15px #ffd700; display:flex; align-items:center; justify-content:center;'><i class='fas fa-store text-dark'></i></div>",
            iconSize: [35, 35],
            iconAnchor: [17, 17]
        });

        const destinationIcon = L.divIcon({
            className: 'custom-div-icon',
            html: "<div style='background-color:#00a8ff; width:22px; height:22px; border-radius:50%; border:2px solid white; box-shadow:0 0 10px #00a8ff;'></div>",
            iconSize: [22, 22],
            iconAnchor: [11, 11]
        });

        // Add Pardede Base Marker
        L.marker([{{ $baseLocation['lat'] }}, {{ $baseLocation['lng'] }}], {icon: baseIcon})
            .addTo(map)
            .bindPopup("<b>{{ $baseLocation['name'] }}</b><br>Pickup Point");

        // Add Destination Markers and Routes
        @foreach($activeOrders as $order)
            @if($order->event_latitude && $order->event_longitude)
                // Marker
                L.marker([{{ $order->event_latitude }}, {{ $order->event_longitude }}], {icon: destinationIcon})
                    .addTo(map)
                    .bindPopup("<b>Order #ORD-{{ str_pad($order->order_id, 5, '0', STR_PAD_LEFT) }}</b><br>{{ $order->event_address }}");

                // Route Line (Follows Roads)
                L.Routing.control({
                    waypoints: [
                        L.latLng({{ $baseLocation['lat'] }}, {{ $baseLocation['lng'] }}),
                        L.latLng({{ $order->event_latitude }}, {{ $order->event_longitude }})
                    ],
                    lineOptions: {
                        styles: [{ color: '#00a8ff', opacity: 0.6, weight: 4 }]
                    },
                    createMarker: function() { return null; }, // Don't add extra markers
                    addWaypoints: false,
                    routeWhileDragging: false,
                    draggableWaypoints: false,
                    fitSelectedRoutes: false,
                    show: false // Hide the directions panel
                }).addTo(map);
            @endif
        @endforeach
    });
</script>

<style>
    /* Hide the Routing Machine directions panel */
    .leaflet-routing-container { display: none !important; }
    
    .bg-primary-light { background: rgba(0, 168, 255, 0.1); color: #00a8ff; border: 1px solid rgba(0, 168, 255, 0.2); }
    .italic { font-style: italic; }
</style>
@endpush
