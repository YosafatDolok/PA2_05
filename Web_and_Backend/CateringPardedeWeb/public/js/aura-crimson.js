document.addEventListener('DOMContentLoaded', () => {
    // Sidebar Mobile Toggle
    const menuToggle = document.querySelector('.aura-menu-toggle');
    const sidebar = document.querySelector('.aura-sidebar');

    if (menuToggle && sidebar) {
        menuToggle.addEventListener('click', (e) => {
            e.stopPropagation();
            sidebar.classList.toggle('active');
        });

        // Close sidebar on click outside
        document.addEventListener('click', (e) => {
            if (sidebar.classList.contains('active') && !sidebar.contains(e.target) && !menuToggle.contains(e.target)) {
                sidebar.classList.remove('active');
            }
        });
    }

    // Interactive Hover Glow Effects
    const cards = document.querySelectorAll('.aura-card');
    cards.forEach(card => {
        card.addEventListener('mousemove', (e) => {
            const rect = card.getBoundingClientRect();
            const x = e.clientX - rect.left;
            const y = e.clientY - rect.top;

            card.style.setProperty('--mouse-x', `${x}px`);
            card.style.setProperty('--mouse-y', `${y}px`);
        });
    });

    // Form focus effects
    const inputs = document.querySelectorAll('.form-control-aura');
    inputs.forEach(input => {
        input.addEventListener('focus', () => {
            input.parentElement.classList.add('focused');
        });
        input.addEventListener('blur', () => {
            input.parentElement.classList.remove('focused');
        });
    });

    // Premium SweetAlert2 Delete Handler
    document.addEventListener('click', (e) => {
        const deleteBtn = e.target.closest('.btn-delete');
        if (deleteBtn) {
            e.preventDefault();
            const itemName = deleteBtn.getAttribute('data-name') || 'this item';
            const form = deleteBtn.closest('form');

            Swal.fire({
                title: 'Are you sure?',
                text: `You are about to delete "${itemName}". This action cannot be undone!`,
                icon: 'warning',
                showCancelButton: true,
                confirmButtonColor: '#ff334b',
                cancelButtonColor: 'rgba(255,255,255,0.1)',
                confirmButtonText: 'Yes, delete it!',
                cancelButtonText: 'Cancel',
                background: 'rgba(15, 15, 20, 0.98)',
                color: '#fff',
                backdrop: `rgba(0,0,0,0.4) blur(4px)`
            }).then((result) => {
                if (result.isConfirmed) {
                    form.submit();
                }
            });
        }
    });

    console.log('Aura-Crimson Logic Engaged');
});
