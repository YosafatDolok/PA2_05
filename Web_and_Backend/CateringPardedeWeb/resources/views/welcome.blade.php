<!DOCTYPE html>
<html lang="{{ str_replace('_', '-', app()->getLocale()) }}">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1, maximum-scale=1, user-scalable=0">
    <title>Pardede Catering</title>

    <!-- Fonts -->
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=Outfit:wght@300;400;500;600;700;800&display=swap" rel="stylesheet">
    
    <!-- Icons -->
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.5.1/css/all.min.css">
    
    <!-- Custom Style -->
    <link rel="stylesheet" href="{{ asset('css/mobile-pardede.css') }}?v={{ time() }}">
</head>
<body>

    <!-- Header -->
    <header class="mobile-header">
        <div>
            <h1 class="brand-title">PARDEDE</h1>
            <span class="brand-subtitle">Exclusive Catering</span>
        </div>
        <div class="header-icons">
            <i class="fas fa-shopping-cart"></i>
            <i class="fas fa-bell"></i>
        </div>
    </header>

    <!-- Category Slider -->
    <section class="category-container">
        <h2 class="section-title">Kategori Menu</h2>
        <div class="category-scroll">
            <div class="category-item active">
                <div class="category-icon">
                    <i class="fas fa-utensils"></i>
                </div>
                <span>Semua</span>
            </div>
            <div class="category-item">
                <div class="category-icon">
                    <i class="fas fa-box"></i>
                </div>
                <span>Nasi Box</span>
            </div>
            <div class="category-item">
                <div class="category-icon">
                    <i class="fas fa-bowl-food"></i>
                </div>
                <span>Tumpeng</span>
            </div>
            <div class="category-item">
                <div class="category-icon">
                    <i class="fas fa-table-list"></i>
                </div>
                <span>Prasmanan</span>
            </div>
            <div class="category-item">
                <div class="category-icon">
                    <i class="fas fa-ice-cream"></i>
                </div>
                <span>Dessert</span>
            </div>
        </div>
    </section>

    <!-- Featured Menus -->
    <section class="content-padding">
        <div class="d-flex justify-content-between align-items-center mb-3" style="display:flex; justify-content: space-between; align-items: center; margin-bottom: 15px;">
            <h2 class="section-title" style="margin-bottom:0;">Menu Terpopuler</h2>
            <span style="font-size: 0.8rem; color: var(--maroon-primary); font-weight: 600;">Lihat Semua</span>
        </div>

        {{-- Product 1 --}}
        <div class="menu-card">
            <img src="{{ asset('storage/tumpeng_nasi_kuning_premium_1776936264946.png') }}" alt="Nasi Tumpeng" class="menu-image">
            <div class="menu-info">
                <div class="badge-category mb-2">TUMPENG</div>
                <h3 class="menu-name">Paket Nasi Tumpeng Tradisional</h3>
                <p class="menu-price">Rp 850.000 <small class="text-muted">/ Paket</small></p>
                <div class="menu-meta">
                    <i class="fas fa-star text-warning"></i> 4.9 (120+ Terjual)
                </div>
            </div>
        </div>

        {{-- Product 2 --}}
        <div class="menu-card">
            <img src="{{ asset('storage/nasibox_premium_final_1776936353978.png') }}" alt="Nasi Box" class="menu-image">
            <div class="menu-info">
                <div class="badge-category mb-2">NASI BOX</div>
                <h3 class="menu-name">Paket Nasi Box Komplit Premium</h3>
                <p class="menu-price">Rp 45.000 <small class="text-muted">/ Box</small></p>
                <div class="menu-meta">
                    <i class="fas fa-star text-warning"></i> 4.8 (500+ Terjual)
                </div>
            </div>
        </div>

        {{-- Product 3 --}}
        <div class="menu-card">
            <img src="{{ asset('storage/prasmanan_lux_mockup_1776936324943.png') }}" alt="Prasmanan" class="menu-image">
            <div class="menu-info">
                <div class="badge-category mb-2">PRASMANAN</div>
                <h3 class="menu-name">Layanan Prasmanan Pernikahan Lux</h3>
                <p class="menu-price">Rp 95.000 <small class="text-muted">/ Porsi</small></p>
                <div class="menu-meta">
                    <i class="fas fa-star text-warning"></i> 5.0 (50+ Acara)
                </div>
            </div>
        </div>
    </section>

    <!-- Bottom Navigation -->
    <nav class="bottom-nav">
        <a href="#" class="nav-item active">
            <i class="fas fa-home"></i>
            <span>Beranda</span>
        </a>
        <a href="#" class="nav-item">
            <i class="fas fa-receipt"></i>
            <span>Pesanan</span>
        </a>
        <a href="#" class="nav-item">
            <i class="fas fa-images"></i>
            <span>Galeri</span>
        </a>
        <a href="{{ route('login') }}" class="nav-item">
            <i class="fas fa-user-circle"></i>
            <span>Profil</span>
        </a>
    </nav>

</body>
</html>
