document.addEventListener('DOMContentLoaded', () => {
    // Sidebar Toggling for Mobile
    const sidebar = document.querySelector('.sidebar');
    const navbarToggler = document.querySelector('.navbar-toggler-neo');
    const mainPanel = document.querySelector('.main-panel');

    if (navbarToggler && sidebar) {
        navbarToggler.addEventListener('click', (e) => {
            e.stopPropagation();
            sidebar.classList.toggle('show');
        });
    }

    // Close sidebar when clicking outside on mobile
    document.addEventListener('click', (e) => {
        if (sidebar && sidebar.classList.contains('show') && !sidebar.contains(e.target)) {
            sidebar.classList.remove('show');
        }
    });

    // Glassmorphism hover focus effect for inputs
    const inputs = document.querySelectorAll('.form-control-neo');
    inputs.forEach(input => {
        input.addEventListener('focus', () => {
            input.parentElement.classList.add('focused');
        });
        input.addEventListener('blur', () => {
            input.parentElement.classList.remove('focused');
        });
    });

    // Initialize Tooltips or other micro-interactions if needed
    console.log('Neo-Dark UI System Initialized');
});
