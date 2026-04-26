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
            <a href="{{ route('profile.edit') }}" class="nav-link">
                <i class="fas fa-user-shield"></i>
                <span>Profile</span>
            </a>
        </li>
    </ul>

    <div class="sidebar-footer p-4">
        <a href="{{ route('logout') }}" class="nav-link text-center text-muted" onclick="event.preventDefault(); document.getElementById('logout-form').submit();">
            <i class="fas fa-power-off"></i>
        </a>
    </div>
</nav>