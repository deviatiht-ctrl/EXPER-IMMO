// navbar.js

document.addEventListener('DOMContentLoaded', () => {
    const navbar = document.getElementById('navbar');
    const btnMenu = document.getElementById('btn-menu');
    const mobileSidebar = document.querySelector('.mobile-sidebar');
    const overlay = document.querySelector('.mobile-sidebar-overlay');

    // Scroll effect
    const checkScroll = () => {
        const isPermanent = navbar.dataset.permanentScrolled === "true";
        if (window.scrollY > 50 || isPermanent) {
            navbar.classList.add('scrolled');
        } else {
            navbar.classList.remove('scrolled');
        }
    };

    window.addEventListener('scroll', checkScroll);
    checkScroll(); // Run once on load

    // Mobile menu toggle
    if (btnMenu) {
        btnMenu.addEventListener('click', () => {
            mobileSidebar.classList.toggle('open');
            overlay.classList.toggle('open');
        });
    }

    if (overlay) {
        overlay.addEventListener('click', () => {
            mobileSidebar.classList.remove('open');
            overlay.classList.remove('open');
        });
    }

    // Initialize Lucide icons (already done in global, but good habit)
    if (window.lucide) {
        lucide.createIcons();
    }
});
