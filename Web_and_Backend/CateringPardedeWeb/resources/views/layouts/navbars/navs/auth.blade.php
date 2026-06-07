<div class="aura-nav-utils d-flex align-items-center">
    {{-- Notifications --}}
    <div class="dropdown me-4">
        <a href="#" class="text-white op-8 position-relative" data-bs-toggle="dropdown" id="notificationBellLink">
            <i class="far fa-bell fs-5"></i>
            @if($unreadCount > 0)
                <span class="position-absolute top-0 start-100 translate-middle p-1 bg-aura-crimson border border-dark rounded-circle pulse-red" style="width: 10px; height: 10px;" id="notificationRedDot"></span>
            @endif
        </a>
        <div class="dropdown-menu dropdown-menu-end aura-dropdown-dark border-0 p-0 mt-3 shadow-lg" style="width: 380px;">
            <div class="p-4 border-bottom border-white-5 d-flex justify-content-between align-items-center">
                <div>
                    <h6 class="mb-0 fw-bold text-white">Notifications</h6>
                    <p class="smaller text-white-50 mb-0">Stay updated with your boutique activity</p>
                </div>
                <span class="badge bg-aura-crimson-soft text-white rounded-pill px-3" id="notificationCountBadge">{{ $unreadCount }} New</span>
            </div>
            <div class="aura-notification-list custom-scrollbar" style="max-height: 420px; overflow-y: auto;" id="notificationList">
                @forelse($notifications as $notification)
                    <a href="{{ $notification->related_id ? route('orders.show', $notification->related_id) : '#' }}" 
                       class="dropdown-item px-4 py-3 notification-item {{ $notification->is_read ? 'op-6' : 'unread-item' }}">
                        <div class="d-flex align-items-center">
                            <div class="aura-icon-circle-sm {{ $notification->type == 'new_order' ? 'bg-warning-transparent text-warning' : 'bg-aura-crimson-transparent text-aura-crimson' }} me-3">
                                <i class="fas {{ $notification->type == 'new_order' ? 'fa-shopping-basket' : 'fa-info-circle' }}"></i>
                            </div>
                            <div class="flex-grow-1">
                                <div class="d-flex justify-content-between align-items-center mb-1">
                                    <p class="mb-0 fw-bold small text-white">{{ $notification->title }}</p>
                                    <p class="mb-0 smaller text-white-50 op-6">{{ $notification->created_at->diffForHumans() }}</p>
                                </div>
                                <p class="mb-0 text-white-50 smaller line-clamp-1">{{ $notification->message }}</p>
                            </div>
                        </div>
                    </a>
                @empty
                    <div class="p-5 text-center" id="emptyNotificationMessage">
                        <div class="op-2 mb-3">
                            <i class="far fa-bell-slash fs-1 text-white"></i>
                        </div>
                        <p class="small text-white-50 mb-0">No new transmissions</p>
                    </div>
                @endforelse
            </div>
            <div class="p-3 bg-aura-dark-footer">
                <a href="{{ route('admin.notifications.index') }}" class="btn btn-aura-crimson-outline btn-sm w-100 fw-bold py-2 rounded-3">VIEW ALL NOTIFICATIONS</a>
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

<script>
    document.addEventListener('DOMContentLoaded', function() {
        const userIdMeta = document.querySelector('meta[name="user-id"]');
        if (!userIdMeta) return;
        const userId = userIdMeta.getAttribute('content');
        if (!userId) return;

        const initEcho = () => {
            if (typeof window.Echo === 'undefined') {
                console.warn('Echo is not initialized yet. Retrying...');
                setTimeout(initEcho, 500);
                return;
            }

            console.log('Subscribing to notification channel for user ' + userId);
            window.Echo.private(`App.Models.User.${userId}`)
                .listen('.notification.sent', (e) => {
                    console.log('Real-time notification received:', e);
                    
                    // 1. Show SweetAlert Toast
                    if (typeof Swal !== 'undefined') {
                        Swal.fire({
                            toast: true,
                            position: 'top-end',
                            showConfirmButton: false,
                            timer: 5000,
                            timerProgressBar: true,
                            icon: e.type === 'new_order' ? 'warning' : 'info',
                            title: e.title,
                            text: e.message,
                            background: '#15151e',
                            color: '#fff',
                            iconColor: e.type === 'new_order' ? '#f39c12' : '#ff334b'
                        });
                    }

                    // 2. Show/update red dot on the bell icon if it doesn't exist
                    let bellLink = document.getElementById('notificationBellLink');
                    if (bellLink) {
                        let redDot = document.getElementById('notificationRedDot');
                        if (!redDot) {
                            redDot = document.createElement('span');
                            redDot.id = 'notificationRedDot';
                            redDot.className = 'position-absolute top-0 start-100 translate-middle p-1 bg-aura-crimson border border-dark rounded-circle pulse-red';
                            redDot.style.width = '10px';
                            redDot.style.height = '10px';
                            bellLink.appendChild(redDot);
                        }
                    }

                    // 3. Update count badge
                    let countBadge = document.getElementById('notificationCountBadge');
                    if (countBadge) {
                        let currentCountText = countBadge.textContent || '0';
                        let currentCount = parseInt(currentCountText) || 0;
                        countBadge.textContent = (currentCount + 1) + ' New';
                    }

                    // 4. Prepend to list
                    let listContainer = document.getElementById('notificationList');
                    if (listContainer) {
                        // Remove empty notification message if present
                        let emptyMsg = document.getElementById('emptyNotificationMessage');
                        if (emptyMsg) {
                            emptyMsg.remove();
                        }

                        let url = '#';
                        if (e.related_id) {
                            url = '{{ route("orders.show", ":id") }}'.replace(':id', e.related_id);
                        }

                        let iconClass = e.type === 'new_order' ? 'bg-warning-transparent text-warning' : 'bg-aura-crimson-transparent text-aura-crimson';
                        let iconName = e.type === 'new_order' ? 'fa-shopping-basket' : 'fa-info-circle';

                        let newItemHtml = `
                            <a href="${url}" class="dropdown-item px-4 py-3 notification-item unread-item">
                                <div class="d-flex align-items-center">
                                    <div class="aura-icon-circle-sm ${iconClass} me-3">
                                        <i class="fas ${iconName}"></i>
                                    </div>
                                    <div class="flex-grow-1">
                                        <div class="d-flex justify-content-between align-items-center mb-1">
                                            <p class="mb-0 fw-bold small text-white">${e.title}</p>
                                            <p class="mb-0 smaller text-white-50 op-6">Just now</p>
                                        </div>
                                        <p class="mb-0 text-white-50 smaller line-clamp-1">${e.message}</p>
                                    </div>
                                </div>
                            </a>
                        `;
                        
                        listContainer.insertAdjacentHTML('afterbegin', newItemHtml);
                    }
                });
        };

        initEcho();
    });
</script>