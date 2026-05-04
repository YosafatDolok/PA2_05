<!DOCTYPE html>
<html lang="{{ str_replace('_', '-', app()->getLocale()) }}">
<head>
    <meta charset="UTF-8">
    <meta http-equiv="X-UA-Compatible" content="ie=edge">
    <meta name="viewport" content="width=device-width, initial-scale=1, shrink-to-fit=no">
    <meta name="csrf-token" content="{{ csrf_token() }}">

    <title>{{ config('app.name', 'Catering Pardede') }} - Admin</title>

    <!-- Essential Libraries (CDN for Robustness) -->
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css" rel="stylesheet">
    <link href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css" rel="stylesheet">
    <link href="https://fonts.googleapis.com/css2?family=Outfit:wght@300;400;500;600;700;800&display=swap" rel="stylesheet">

    <!-- Aura-Crimson Standalone Design System -->
    <link href="{{ asset('css/aura-crimson.css') }}?v={{ time() }}" rel="stylesheet"/>

    <style>
        /* Premium Error & Warning Styles */
        .form-control-aura.is-invalid, 
        .form-control.is-invalid {
            border-color: #ff334b !important;
            box-shadow: 0 0 15px rgba(255, 51, 75, 0.2) !important;
            background: rgba(255, 51, 75, 0.05) !important;
            animation: aura-shake 0.4s cubic-bezier(.36,.07,.19,.97) both;
        }

        .invalid-feedback {
            color: #ff334b !important;
            font-size: 0.75rem !important;
            font-style: italic;
            margin-top: 8px;
            display: block;
            font-weight: 500;
            letter-spacing: 0.5px;
        }

        @keyframes aura-shake {
            10%, 90% { transform: translate3d(-1px, 0, 0); }
            20%, 80% { transform: translate3d(2px, 0, 0); }
            30%, 50%, 70% { transform: translate3d(-4px, 0, 0); }
            40%, 60% { transform: translate3d(4px, 0, 0); }
        }

        .animate-pulse-crimson {
            animation: pulse-crimson 2s infinite;
        }

        @keyframes pulse-crimson {
            0% { box-shadow: 0 0 0 0 rgba(255, 51, 75, 0.4); }
            70% { box-shadow: 0 0 0 10px rgba(255, 51, 75, 0); }
            100% { box-shadow: 0 0 0 0 rgba(255, 51, 75, 0); }
        }

        /* Badge Dot */
        .badge-dot {
            width: 8px;
            height: 8px;
            background: #ff334b;
            border-radius: 50%;
            display: inline-block;
            margin-left: 8px;
            box-shadow: 0 0 10px rgba(255, 51, 75, 0.5);
        }
        /* Global Search Styles - Premium Overhaul */
        .search-box {
            position: relative;
        }

        .aura-search-results {
            position: absolute;
            top: 100%;
            right: 0;
            width: 400px; /* Wider for premium feel */
            background: rgba(15, 15, 20, 0.98);
            backdrop-filter: blur(25px);
            border: 1px solid rgba(255, 255, 255, 0.08);
            border-radius: 20px;
            margin-top: 15px;
            z-index: 1000;
            display: none;
            box-shadow: 0 20px 50px rgba(0,0,0,0.8);
            overflow: hidden;
            animation: auraFadeIn 0.2s ease-out;
        }

        @keyframes auraFadeIn {
            from { opacity: 0; transform: translateY(-10px); }
            to { opacity: 1; transform: translateY(0); }
        }

        .search-result-category {
            font-size: 0.7rem;
            font-weight: 800;
            color: var(--aura-crimson, #ff334b);
            padding: 15px 20px 8px;
            text-transform: uppercase;
            letter-spacing: 1.5px;
            background: rgba(255,255,255,0.02);
            border-bottom: 1px solid rgba(255,255,255,0.03);
        }

        .search-result-item {
            padding: 14px 20px;
            display: grid;
            grid-template-columns: 45px 1fr;
            align-items: center;
            color: rgba(255,255,255,0.85);
            text-decoration: none !important;
            transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1);
            border-bottom: 1px solid rgba(255,255,255,0.03);
            width: 100%;
            overflow: hidden;
            outline: none;
        }

        .search-result-item.active {
            background: rgba(255, 51, 75, 0.2) !important;
            color: #fff;
            border-left: 3px solid #ff334b;
        }

        .search-thumbnail {
            width: 32px;
            height: 32px;
            border-radius: 50%;
            object-fit: cover;
            border: 1px solid rgba(255,255,255,0.1);
        }

        .search-result-item:last-child {
            border-bottom: none;
        }

        .search-result-item i {
            width: 32px;
            height: 32px;
            position: static !important;
            display: flex !important;
            align-items: center;
            justify-content: center;
            background: rgba(255,255,255,0.05);
            border-radius: 10px;
            font-size: 0.9rem;
            transition: all 0.3s;
        }

        /* Loading Search Icon */
        .search-box.loading i.fa-search {
            color: #ff334b;
        }

        .search-result-item:hover {
            background: rgba(255, 51, 75, 0.08);
            color: #fff;
            padding-left: 25px; /* Subtle slide effect */
        }

        .search-result-item:hover i {
            background: var(--aura-crimson, #ff334b);
            color: white;
            box-shadow: 0 0 15px rgba(255, 51, 75, 0.4);
            transform: scale(1.1);
        }

        .search-result-title {
            font-weight: 600;
            font-size: 0.85rem;
            letter-spacing: 0.3px;
            white-space: nowrap;
            overflow: hidden;
            text-overflow: ellipsis;
            padding-left: 5px;
        }

        /* Message Badges */
        .bg-crimson { background: #ff334b !important; color: white !important; }
        .pulse-mini {
            animation: pulse-mini 1.5s infinite;
            box-shadow: 0 0 0 rgba(255, 51, 75, 0.4);
        }
        @keyframes pulse-mini {
            0% { transform: scale(0.95); box-shadow: 0 0 0 0 rgba(255, 51, 75, 0.7); }
            70% { transform: scale(1); box-shadow: 0 0 0 5px rgba(255, 51, 75, 0); }
            100% { transform: scale(0.95); box-shadow: 0 0 0 0 rgba(255, 51, 75, 0); }
        }
    </style>
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
                    <div class="search-box me-4 d-none d-md-block" id="globalSearchBox">
                        <i class="fas fa-search"></i>
                        <input type="text" id="globalSearchInput" placeholder="Search anything..." autocomplete="off">
                        <div id="globalSearchResults" class="aura-search-results"></div>
                    </div>
                    @include('layouts.navbars.navs.auth')
                </div>
            </header>

            <section class="aura-content">
                <div class="container-fluid p-0">
                    @yield('content')
                </div>
            </section>

            <footer class="aura-footer text-center py-4 mt-auto">
                <p class="text-muted small mb-0">&copy; {{ date('Y') }} Catering Pardede. Crafted for visual excellence.</p>
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

<script>
    document.addEventListener('DOMContentLoaded', function() {
        const searchInput = document.getElementById('globalSearchInput');
        const searchResults = document.getElementById('globalSearchResults');
        const searchBox = document.getElementById('globalSearchBox');
        let debounceTimer;
        let currentIndex = -1;

        const updateActiveResult = () => {
            const items = searchResults.querySelectorAll('.search-result-item');
            items.forEach((item, index) => {
                if (index === currentIndex) {
                    item.classList.add('active');
                    item.scrollIntoView({ block: 'nearest' });
                } else {
                    item.classList.remove('active');
                }
            });
        };

        searchInput.addEventListener('keydown', function(e) {
            const items = searchResults.querySelectorAll('.search-result-item');
            
            if (e.key === 'ArrowDown') {
                e.preventDefault();
                currentIndex = (currentIndex + 1) % items.length;
                updateActiveResult();
            } else if (e.key === 'ArrowUp') {
                e.preventDefault();
                currentIndex = (currentIndex - 1 + items.length) % items.length;
                updateActiveResult();
            } else if (e.key === 'Enter') {
                if (currentIndex > -1 && items[currentIndex]) {
                    e.preventDefault();
                    items[currentIndex].click();
                }
            } else if (e.key === 'Escape') {
                searchResults.style.display = 'none';
                currentIndex = -1;
            }
        });

        searchInput.addEventListener('input', function() {
            clearTimeout(debounceTimer);
            const query = this.value;
            currentIndex = -1;

            if (query.length < 1) {
                searchResults.style.display = 'none';
                return;
            }

            searchBox.classList.add('loading');

            debounceTimer = setTimeout(() => {
                fetch(`{{ route('admin.global-search') }}?query=${encodeURIComponent(query)}`)
                    .then(response => response.json())
                    .then(data => {
                        searchBox.classList.remove('loading');
                        if (data.length > 0) {
                            let html = '';
                            let currentType = '';
                            
                            data.forEach(item => {
                                if (item.type !== currentType) {
                                    html += `<div class="search-result-category">${item.type}S</div>`;
                                    currentType = item.type;
                                }
                                html += `
                                    <a href="${item.url}" class="search-result-item">
                                        ${item.image ? `<img src="${item.image}" class="search-thumbnail">` : `<i class="${item.icon}"></i>`}
                                        <div>
                                            <div class="search-result-title">${item.title}</div>
                                            ${item.subtitle ? `<div class="smaller text-white-50">${item.subtitle}</div>` : ''}
                                        </div>
                                    </a>
                                `;
                            });
                            searchResults.innerHTML = html;
                            searchResults.style.display = 'block';
                        } else {
                            searchResults.innerHTML = '<div class="p-4 text-center text-muted small">No results found</div>';
                            searchResults.style.display = 'block';
                        }
                    })
                    .catch(() => {
                        searchBox.classList.remove('loading');
                    });
            }, 300);
        });

        // Hide results when clicking outside
        document.addEventListener('click', function(e) {
            if (!searchInput.contains(e.target) && !searchResults.contains(e.target)) {
                searchResults.style.display = 'none';
                currentIndex = -1;
            }
        });
    });
</script>

</body>
</html>
