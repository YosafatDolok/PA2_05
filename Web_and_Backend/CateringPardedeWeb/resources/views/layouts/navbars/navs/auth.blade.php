<div class="aura-nav-utils d-flex align-items-center">
    {{-- Notifications --}}
    <div class="dropdown me-4">
        <a href="#" class="text-white op-8 position-relative" data-bs-toggle="dropdown">
            <i class="far fa-bell fs-5"></i>
            <span class="position-absolute top-0 start-100 translate-middle p-1 bg-danger border border-light rounded-circle" style="width: 8px; height: 8px;"></span>
        </a>
        <div class="dropdown-menu dropdown-menu-end aura-card border-0 p-3 mt-3" style="width: 300px;">
            <p class="small text-muted mb-0 text-center">No new transmissions</p>
        </div>
    </div>

    {{-- User Profile --}}
    <div class="dropdown">
        <a href="#" class="d-flex align-items-center text-decoration-none" data-bs-toggle="dropdown">
            <div class="aura-avatar me-2">
                @if(auth()->user()->profile_picture)
                    <img src="{{ asset('storage/' . auth()->user()->profile_picture) }}" alt="User" class="rounded-circle border border-danger" width="40" height="40" style="object-fit: cover;">
                @else
                    <img src="https://ui-avatars.com/api/?name={{ urlencode(auth()->user()->name) }}&background=EB4D4B&color=fff" alt="User" class="rounded-circle border border-danger" width="40" height="40">
                @endif
            </div>
            <i class="fas fa-chevron-down text-muted small"></i>
        </a>
        <ul class="dropdown-menu dropdown-menu-end p-2 mt-3 shadow-lg" style="min-width: 200px;">
            <li>
                <a href="{{ route('profile.edit') }}" class="dropdown-item py-2 px-3 rounded-3 mb-1">
                    <i class="fas fa-user-gear text-danger"></i> Profile Settings
                </a>
            </li>
            <li><hr class="dropdown-divider"></li>
            <li>
                <a href="#" class="dropdown-item py-2 px-3 rounded-3 text-danger" onclick="event.preventDefault(); document.getElementById('logout-form').submit();">
                    <i class="fas fa-power-off"></i> Logout
                </a>
            </li>
        </ul>
        <form id="logout-form" action="{{ route('logout') }}" method="POST" style="display: none;">
            @csrf
        </form>
    </div>
</div>

{{-- Search Modal --}}
<div class="modal modal-search fade" id="searchModal" tabindex="-1">
    <div class="modal-dialog">
        <div class="modal-content glass-card border-0">
            <div class="modal-header border-0">
                <input type="text" class="form-control form-control-neo" placeholder="{{ __('SEARCH...') }}">
                <button type="button" class="close text-white" data-dismiss="modal">
                    <i class="fas fa-times"></i>
                </button>
            </div>
        </div>
    </div>
</div>