/**
 * EXPER IMMO - Modern Navbar Controller
 * Gestion du navbar glassmorphic avec authentification
 */

import { supabase } from './supabase-client.js';

class NavbarController {
    constructor() {
        this.currentUser = null;
        this.userProfile = null;
        this.init();
    }

    async init() {
        // Attendre que le navbar soit chargé
        await this.waitForNavbar();
        
        this.setupScrollEffect();
        this.setupMobileMenu();
        this.setupBottomNav();
        this.setupSearchToggle();
        this.setupActiveLink();
        await this.checkAuth();
        this.setupLogout();
    }

    // Attendre que le navbar soit injecté dans le DOM
    waitForNavbar() {
        return new Promise((resolve) => {
            const checkNavbar = () => {
                const navbar = document.getElementById('navbar');
                const btnMenu = document.getElementById('btn-menu');
                if (navbar && btnMenu) {
                    resolve();
                } else {
                    setTimeout(checkNavbar, 50);
                }
            };
            checkNavbar();
        });
    }

    // Effet scroll sur navbar
    setupScrollEffect() {
        const navbar = document.getElementById('navbar');
        if (!navbar) return;

        let lastScroll = 0;
        
        window.addEventListener('scroll', () => {
            const currentScroll = window.pageYOffset;
            
            if (currentScroll > 50) {
                navbar.classList.add('scrolled');
            } else {
                navbar.classList.remove('scrolled');
            }
            
            lastScroll = currentScroll;
        }, { passive: true });
    }

    // Bottom Navigation (Mobile App Style)
    setupBottomNav() {
        const bottomNav = document.getElementById('bottom-nav');
        if (!bottomNav) return;

        // Set active link based on current page
        const currentPage = window.location.pathname.split('/').pop() || 'index.html';
        const currentParams = window.location.search;

        bottomNav.querySelectorAll('.bottom-nav-item').forEach(item => {
            const href = item.getAttribute('href');
            let isActive = false;

            if (href === currentPage) {
                isActive = true;
            } else if (currentPage === 'proprietes.html') {
                if (currentParams.includes('type=vente') && href.includes('vente')) {
                    isActive = true;
                } else if (currentParams.includes('type=location') && href.includes('location')) {
                    isActive = true;
                }
            }

            if (isActive) {
                item.classList.add('active');
            } else {
                item.classList.remove('active');
            }
        });
    }

    // Menu mobile
    setupMobileMenu() {
        const btnMenu = document.getElementById('btn-menu');
        const btnClose = document.getElementById('btn-close-menu');
        const sidebar = document.getElementById('mobile-sidebar');
        const overlay = document.getElementById('mobile-overlay');

        console.log('Mobile menu setup:', { btnMenu, sidebar, btnClose, overlay });

        if (!btnMenu || !sidebar) {
            console.warn('Mobile menu elements not found');
            return;
        }

        const openMenu = (e) => {
            e.preventDefault();
            e.stopPropagation();
            console.log('Opening menu...');
            sidebar.classList.add('active');
            if (overlay) overlay.classList.add('active');
            document.body.style.overflow = 'hidden';
        };

        const closeMenu = (e) => {
            if (e) {
                e.preventDefault();
                e.stopPropagation();
            }
            console.log('Closing menu...');
            sidebar.classList.remove('active');
            if (overlay) overlay.classList.remove('active');
            document.body.style.overflow = '';
        };

        btnMenu.addEventListener('click', openMenu);
        btnClose?.addEventListener('click', closeMenu);
        overlay?.addEventListener('click', closeMenu);

        // Fermer au clic sur un lien
        sidebar.querySelectorAll('a').forEach(link => {
            link.addEventListener('click', closeMenu);
        });
    }

    // Toggle recherche
    setupSearchToggle() {
        const btnSearch = document.getElementById('btn-search-toggle');
        if (!btnSearch) return;

        btnSearch.addEventListener('click', () => {
            // Rediriger vers page propriétés avec focus recherche
            window.location.href = 'proprietes.html?focus=search';
        });
    }

    // Lien actif
    setupActiveLink() {
        const currentPage = window.location.pathname.split('/').pop() || 'index.html';
        const currentParams = window.location.search;

        // Desktop links
        document.querySelectorAll('.nav-link').forEach(link => {
            const href = link.getAttribute('href');
            if (href === currentPage || href?.includes(currentPage)) {
                // Vérifier aussi les paramètres
                if (currentPage === 'proprietes.html') {
                    if (currentParams.includes('type=vente') && href.includes('vente')) {
                        link.classList.add('active');
                    } else if (currentParams.includes('type=location') && href.includes('location')) {
                        link.classList.add('active');
                    } else if (!currentParams && href === currentPage) {
                        link.classList.add('active');
                    }
                } else {
                    link.classList.add('active');
                }
            }
        });

        // Mobile links
        document.querySelectorAll('.mobile-nav-links a').forEach(link => {
            const href = link.getAttribute('href');
            if (href === currentPage || href?.includes(currentPage)) {
                link.classList.add('active');
            }
        });
    }

    // Vérifier authentification
    async checkAuth() {
        try {
            const { data: { session }, error } = await supabase.auth.getSession();
            
            if (session?.user) {
                this.currentUser = session.user;
                await this.loadUserProfile(session.user.id);
                this.showConnectedUI();
            } else {
                this.showNotConnectedUI();
            }
        } catch (err) {
            console.error('Auth check error:', err);
            this.showNotConnectedUI();
        }
    }

    // Charger profil utilisateur
    async loadUserProfile(userId) {
        try {
            const { data, error } = await supabase
                .from('profiles')
                .select('*')
                /* .eq('id', userId) - TODO: filter nan server */
                [0];

            this.userProfile = data;
            this.updateUserUI(data);
        } catch (err) {
            console.error('Profile load error:', err);
        }
    }

    // Afficher UI connecté
    showConnectedUI() {
        // Desktop
        const notConnected = document.getElementById('nav-not-connected');
        const connected = document.getElementById('nav-connected');
        
        if (notConnected) notConnected.style.display = 'none';
        if (connected) connected.style.display = 'flex';

        // Mobile sidebar
        const sidebarNotConnected = document.getElementById('sidebar-not-connected');
        const sidebarConnected = document.getElementById('sidebar-connected');
        const sidebarMenu = document.getElementById('sidebar-menu-connected');

        if (sidebarNotConnected) sidebarNotConnected.style.display = 'none';
        if (sidebarConnected) sidebarConnected.style.display = 'block';
        if (sidebarMenu) sidebarMenu.style.display = 'block';
    }

    // Afficher UI non connecté
    showNotConnectedUI() {
        // Desktop
        const notConnected = document.getElementById('nav-not-connected');
        const connected = document.getElementById('nav-connected');
        
        if (notConnected) notConnected.style.display = 'flex';
        if (connected) connected.style.display = 'none';

        // Mobile sidebar
        const sidebarNotConnected = document.getElementById('sidebar-not-connected');
        const sidebarConnected = document.getElementById('sidebar-connected');
        const sidebarMenu = document.getElementById('sidebar-menu-connected');

        if (sidebarNotConnected) sidebarNotConnected.style.display = 'flex';
        if (sidebarConnected) sidebarConnected.style.display = 'none';
        if (sidebarMenu) sidebarMenu.style.display = 'none';
    }

    // Mettre à jour UI utilisateur
    updateUserUI(profile) {
        if (!profile) return;

        const fullName = profile.full_name || 'Utilisateur';
        const initials = this.getInitials(fullName);
        const role = profile.role || 'locataire';

        // Desktop navbar
        const userName = document.getElementById('nav-user-name');
        const userAvatar = document.getElementById('nav-user-avatar');
        const dropdownName = document.getElementById('dropdown-name');
        const dropdownRole = document.getElementById('dropdown-role');

        if (userName) userName.textContent = fullName;
        if (userAvatar) userAvatar.textContent = initials;
        if (dropdownName) dropdownName.textContent = fullName;
        if (dropdownRole) dropdownRole.textContent = this.formatRole(role);

        // Mobile sidebar
        const sidebarName = document.getElementById('sidebar-name');
        const sidebarRole = document.getElementById('sidebar-role');
        const sidebarAvatar = document.getElementById('sidebar-avatar');

        if (sidebarName) sidebarName.textContent = fullName;
        if (sidebarRole) sidebarRole.textContent = this.formatRole(role);
        if (sidebarAvatar) sidebarAvatar.textContent = initials;

        // Afficher menu selon rôle
        this.showRoleMenu(role);

        // Afficher bouton admin si admin
        if (role === 'admin') {
            const adminBtn = document.getElementById('nav-admin-btn');
            if (adminBtn) adminBtn.style.display = 'flex';
        }
    }

    // Afficher menu selon rôle
    showRoleMenu(role) {
        // Desktop dropdown
        const menuProprietaire = document.getElementById('menu-proprietaire');
        const menuLocataire = document.getElementById('menu-locataire');
        const menuAdmin = document.getElementById('menu-admin');

        // Mobile sidebar
        const linkProprietaire = document.getElementById('sidebar-link-proprietaire');
        const linkLocataire = document.getElementById('sidebar-link-locataire');
        const linkAdmin = document.getElementById('sidebar-link-admin');

        // Cacher tout d'abord
        if (menuProprietaire) menuProprietaire.style.display = 'none';
        if (menuLocataire) menuLocataire.style.display = 'none';
        if (menuAdmin) menuAdmin.style.display = 'none';
        if (linkProprietaire) linkProprietaire.style.display = 'none';
        if (linkLocataire) linkLocataire.style.display = 'none';
        if (linkAdmin) linkAdmin.style.display = 'none';

        // Afficher selon rôle
        switch (role) {
            case 'proprietaire':
                if (menuProprietaire) menuProprietaire.style.display = 'block';
                if (linkProprietaire) linkProprietaire.style.display = 'flex';
                break;
            case 'locataire':
                if (menuLocataire) menuLocataire.style.display = 'block';
                if (linkLocataire) linkLocataire.style.display = 'flex';
                break;
            case 'admin':
                if (menuAdmin) menuAdmin.style.display = 'block';
                if (linkAdmin) linkAdmin.style.display = 'flex';
                // Admin voit aussi les autres menus
                if (menuProprietaire) menuProprietaire.style.display = 'block';
                if (menuLocataire) menuLocataire.style.display = 'block';
                break;
        }
    }

    // Format rôle
    formatRole(role) {
        const roles = {
            'admin': 'Administrateur',
            'proprietaire': 'Propriétaire',
            'locataire': 'Locataire'
        };
        return roles[role] || role;
    }

    // Obtenir initiales
    getInitials(name) {
        if (!name) return 'U';
        return name
            .split(' ')
            .map(n => n[0])
            .join('')
            .toUpperCase()
            .slice(0, 2);
    }

    // Déconnexion
    setupLogout() {
        const btnLogout = document.getElementById('btn-logout');
        const sidebarLogout = document.getElementById('sidebar-logout');

        const logout = async (e) => {
            e.preventDefault();
            
            try {
                const { error } = localStorage.removeItem('exper_immo_token'); localStorage.removeItem('exper_immo_user');
                window.location.href = 'index.html';
            } catch (err) {
                console.error('Logout error:', err);
                alert('Erreur lors de la déconnexion');
            }
        };

        if (btnLogout) btnLogout.addEventListener('click', logout);
        if (sidebarLogout) sidebarLogout.addEventListener('click', logout);
    }

    // Mettre à jour compteur favoris
    updateFavoritesCount(count) {
        const badge = document.getElementById('fav-count');
        if (badge) {
            badge.textContent = count;
            badge.style.display = count > 0 ? 'flex' : 'none';
        }
    }
}

// Initialiser
const navbarController = new NavbarController();

// Exporter pour utilisation externe
export { navbarController };
export default NavbarController;
