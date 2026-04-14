<nav class="navbar navbar-expand-lg navbar-absolute navbar-transparent">
    <div class="container-fluid">
        <div class="navbar-wrapper">
            <div class="navbar-toggle d-inline">
                <button type="button" class="navbar-toggler">
                    <span class="navbar-toggler-bar bar1"></span>
                    <span class="navbar-toggler-bar bar2"></span>
                    <span class="navbar-toggler-bar bar3"></span>
                </button>
            </div>
            <a class="navbar-brand" href="#">
                {{ $page ?? __('Dashboard') }}
            </a>
        </div>

        <button class="navbar-toggler" type="button" data-toggle="collapse" data-target="#navigation">
            <span class="navbar-toggler-bar navbar-kebab"></span>
            <span class="navbar-toggler-bar navbar-kebab"></span>
            <span class="navbar-toggler-bar navbar-kebab"></span>
        </button>

        <div class="collapse navbar-collapse" id="navigation">
            <ul class="navbar-nav ml-auto">

                {{-- Search --}}
                <li class="search-bar input-group">
                    <button class="btn btn-link" data-toggle="modal" data-target="#searchModal">
                        <i class="tim-icons icon-zoom-split"></i>
                    </button>
                </li>

                {{-- Notifications (static) --}}
                <li class="dropdown nav-item">
                    <a href="#" class="dropdown-toggle nav-link" data-toggle="dropdown">
                        <i class="tim-icons icon-sound-wave"></i>
                    </a>
                    <ul class="dropdown-menu dropdown-menu-right dropdown-navbar">
                        <li class="nav-link">
                            <a href="#" class="nav-item dropdown-item">No notifications</a>
                        </li>
                    </ul>
                </li>

                {{-- User Dropdown --}}
                <li class="dropdown nav-item">
                    <a href="#" class="dropdown-toggle nav-link" data-toggle="dropdown">
                        <div class="photo">
                            <img src="{{ asset('black/img/anime3.png') }}" alt="Profile Photo">
                        </div>
                    </a>

                    <ul class="dropdown-menu dropdown-navbar">
                        <li class="nav-link">
                            <a href=# class="nav-item dropdown-item">
                                {{ __('Profile') }}
                            </a>
                        </li>

                        <li class="nav-link">
                            <a href="#" class="nav-item dropdown-item">
                                {{ __('Settings') }}
                            </a>
                        </li>

                        <li class="dropdown-divider"></li>

                        <li class="nav-link">
                            <a href="#" class="nav-item dropdown-item"
                               onclick="event.preventDefault(); document.getElementById('logout-form').submit();">
                                {{ __('Log out') }}
                            </a>
                        </li>
                    </ul>
                </li>

                <li class="separator d-lg-none"></li>
            </ul>
        </div>
    </div>
</nav>

{{-- Logout Form --}}
<form id="logout-form" action="{{ route('logout') }}" method="POST" style="display: none;">
    @csrf
</form>

{{-- Search Modal --}}
<div class="modal modal-search fade" id="searchModal" tabindex="-1">
    <div class="modal-dialog">
        <div class="modal-content">
            <div class="modal-header">
                <input type="text" class="form-control" placeholder="SEARCH">
                <button type="button" class="close" data-dismiss="modal">
                    <i class="tim-icons icon-simple-remove"></i>
                </button>
            </div>
        </div>
    </div>
</div>