<nav class="aura-sidebar">
    <div class="sidebar-header">
        <h1 class="sidebar-logo">Pardede</h1>
    </div>

    <ul class="sidebar-nav">
        {{-- Dashboard --}}
        <li class="nav-item {{ request()->routeIs('admin.dashboard') ? 'active' : '' }}">
            <a href="{{ route('admin.dashboard') }}" class="nav-link">
                <i class="fas fa-rocket"></i>
                <span>Dashboard</span>
            </a>
        </li>

        {{-- Menus --}}
        <li class="nav-item {{ request()->routeIs('menus.*') ? 'active' : '' }}">
            <a href="{{ route('menus.index') }}" class="nav-link">
                <i class="fas fa-utensils"></i>
                <span>Menus</span>
            </a>
        </li>

        {{-- Orders --}}
        <li class="nav-item {{ request()->routeIs('orders.*') ? 'active' : '' }}">
            <a href="{{ route('orders.index') }}" class="nav-link">
                <i class="fas fa-box-open"></i>
                <span>Orders</span>
                @if($pendingOrdersCount > 0)
                    <span class="badge-dot animate-pulse-crimson"></span>
                @endif
            </a>
        </li>

        {{-- Messages --}}
        <li class="nav-item {{ request()->routeIs('admin.messages') ? 'active' : '' }}">
            <a href="{{ route('admin.messages') }}" class="nav-link">
                <i class="fas fa-comments"></i>
                <span>Messages</span>
                @if($unreadMessagesTotalCount > 0)
                    <span class="badge bg-crimson pulse-mini ms-auto" style="font-size: 0.6rem; padding: 0.3em 0.6em;">
                        {{ $unreadMessagesTotalCount }}
                    </span>
                @endif
            </a>
        </li>

        {{-- Order Additions --}}
        <li class="nav-item {{ request()->routeIs('admin.additions.*') ? 'active' : '' }}">
            <a href="{{ route('admin.additions.index') }}" class="nav-link">
                <i class="fas fa-plus-circle"></i>
                <span>Additions</span>
                @if($pendingAdditionsCount > 0)
                    <span class="badge-dot animate-pulse-crimson"></span>
                @endif
            </a>
        </li>

        {{-- Categories --}}
        <li class="nav-item {{ request()->routeIs('categories.*') ? 'active' : '' }}">
            <a href="{{ route('categories.index') }}" class="nav-link">
                <i class="fas fa-tags"></i>
                <span>Categories</span>
            </a>
        </li>

        {{-- Galleries --}}
        <li class="nav-item {{ request()->routeIs('galleries.*') ? 'active' : '' }}">
            <a href="{{ route('galleries.index') }}" class="nav-link">
                <i class="fas fa-camera-retro"></i>
                <span>Gallery</span>
            </a>
        </li>

        {{-- Profile --}}
        <li class="nav-item {{ request()->routeIs('profile.edit') ? 'active' : '' }}">
            <a class="nav-link" href="{{ route('profile.edit') }}">
                <i class="fas fa-user-cog"></i>
                <span>Profile</span>
            </a>
        </li>
        <li class="nav-item {{ request()->routeIs('admin.reviews.index') ? 'active' : '' }}">
            <a class="nav-link" href="{{ route('admin.reviews.index') }}">
                <i class="fas fa-star"></i>
                <span>Reviews</span>
            </a>
        </li>
    </ul>

    <div class="sidebar-footer p-4">
        <a href="{{ route('logout') }}" class="nav-link text-center text-muted" onclick="event.preventDefault(); document.getElementById('logout-form').submit();">
            <i class="fas fa-power-off"></i>
        </a>
    </div>
</nav>