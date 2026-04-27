<div class="aura-nav-utils d-flex align-items-center">
    {{-- Notifications --}}
    <div class="dropdown me-4">
        <a href="#" class="text-white op-8 position-relative" data-bs-toggle="dropdown">
            <i class="far fa-bell fs-5"></i>
            @if($unreadCount > 0)
                <span class="position-absolute top-0 start-100 translate-middle p-1 bg-aura-crimson border border-dark rounded-circle pulse-red" style="width: 10px; height: 10px;"></span>
            @endif
        </a>
        <div class="dropdown-menu dropdown-menu-end aura-dropdown-dark border-0 p-0 mt-3 shadow-lg" style="width: 320px;">
            <div class="p-3 border-bottom border-white-5 d-flex justify-content-between align-items-center">
                <h6 class="mb-0 fw-bold text-white">Notifications</h6>
                <span class="badge bg-aura-crimson-soft text-aura-crimson rounded-pill px-3">{{ $unreadCount }} New</span>
            </div>
            <div class="aura-notification-list custom-scrollbar" style="max-height: 350px; overflow-y: auto;">
                @forelse($notifications as $notification)
                    <a href="{{ $notification->related_id ? route('orders.show', $notification->related_id) : '#' }}" 
                       class="dropdown-item p-3 border-bottom border-white-5 notification-item {{ $notification->is_read ? 'op-6' : 'unread-item' }}">
                        <div class="d-flex align-items-start">
                            <div class="aura-icon-circle-sm bg-aura-crimson-transparent text-aura-crimson me-3">
                                <i class="fas {{ $notification->type == 'new_order' ? 'fa-shopping-basket' : 'fa-info-circle' }}"></i>
                            </div>
                            <div class="flex-grow-1">
                                <p class="mb-1 fw-bold small text-white">{{ $notification->title }}</p>
                                <p class="mb-1 text-white-50 smaller">{{ $notification->message }}</p>
                                <p class="mb-0 smaller text-aura-crimson op-8 fw-bold">{{ $notification->created_at->diffForHumans() }}</p>
                            </div>
                        </div>
                    </a>
                @empty
                    <div class="p-5 text-center">
                        <div class="op-2 mb-3">
                            <i class="far fa-bell-slash fs-1 text-white"></i>
                        </div>
                        <p class="small text-white-50 mb-0">No new transmissions</p>
                    </div>
                @endforelse
            </div>
            <div class="p-2">
                <a href="#" class="btn btn-aura-crimson-outline btn-sm w-100 fw-bold py-2">VIEW ALL NOTIFICATIONS</a>
            </div>
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