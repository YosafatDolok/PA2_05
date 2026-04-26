document.addEventListener('DOMContentLoaded', () => {
    // Sidebar Toggling for Mobile
    const sidebar = document.querySelector('.sidebar-floating');
    const toggleBtn = document.createElement('button');
    toggleBtn.className = 'btn btn-icon btn-crimson sidebar-toggler-mobile d-lg-none';
    toggleBtn.innerHTML = '<i class="fas fa-bars"></i>';
    toggleBtn.style.position = 'fixed';
    toggleBtn.style.bottom = '20px';
    toggleBtn.style.right = '20px';
    toggleBtn.style.zIndex = '1001';
    toggleBtn.style.borderRadius = '50%';

    if (sidebar) {
        document.body.appendChild(toggleBtn);

        toggleBtn.addEventListener('click', () => {
            sidebar.classList.toggle('show');
            toggleBtn.innerHTML = sidebar.classList.contains('show')
                ? '<i class="fas fa-times"></i>'
                : '<i class="fas fa-bars"></i>';
        });

        // Close sidebar when clicking outside on mobile
        document.addEventListener('click', (e) => {
            if (sidebar.classList.contains('show') && !sidebar.contains(e.target) && !toggleBtn.contains(e.target)) {
                sidebar.classList.remove('show');
                toggleBtn.innerHTML = '<i class="fas fa-bars"></i>';
            }
        });
    }

    // Hover sound/animation logic could go here
    console.log('Crimson-White UI System Initialized');
});
