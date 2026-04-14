<div class="sidebar">
    <div class="sidebar-wrapper">
        <div class="logo">
            <a href="#" class="simple-text logo-mini">{{ __('BD') }}</a>
            <a href="#" class="simple-text logo-normal">{{ __('Admin Panel') }}</a>
        </div>

        <ul class="nav">
            {{-- Dashboard --}}
            <li class="{{ request()->routeIs('admin.dashboard') ? 'active' : '' }}">
                <a href="{{ route('admin.dashboard') }}">
                    <i class="tim-icons icon-chart-pie-36"></i>
                    <p>{{ __('Dashboard') }}</p>
                </a>
            </li>

            {{-- Menus --}}
            <li class="{{ request()->routeIs('menus.*') ? 'active' : '' }}">
                <a href="{{ route('menus.index') }}">
                    <i class="tim-icons icon-bullet-list-67"></i>
                    <p>{{ __('Menus') }}</p>
                </a>
            </li>

            {{-- Categories --}}
            <li class="{{ request()->routeIs('categories.*') ? 'active' : '' }}">
                <a href="{{ route('categories.index') }}">
                    <i class="tim-icons icon-tag"></i>
                    <p>{{ __('Categories') }}</p>
                </a>
            </li>

            {{-- Galleries --}}
            <li class="{{ request()->routeIs('galleries.*') ? 'active' : '' }}">
                <a href="{{ route('galleries.index') }}">
                    <i class="tim-icons icon-image-02"></i>
                    <p>{{ __('Galleries') }}</p>
                </a>
            </li>

            {{-- Profile --}}
            <li>
                <a href="{{ route('profile.edit') }}">
                    <i class="tim-icons icon-single-02"></i>
                    <p>Profile</p>
                </a>
            </li>

            {{-- Logout --}}
            <li>
                <a href="#" onclick="event.preventDefault(); document.getElementById('logout-form').submit();">
                    <i class="tim-icons icon-button-power"></i>
                    <p>{{ __('Logout') }}</p>
                </a>

                <form id="logout-form" action="{{ url('/logout') }}" method="POST" style="display: none;">
                    @csrf
                </form>
            </li>
        </ul>
    </div>
</div>