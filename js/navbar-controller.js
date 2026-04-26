import apiClient from './api-client.js';

// Déterminer le préfixe du chemin
const folders = ['admin', 'gestionnaire', 'locataire', 'proprietaire', 'properties'];
const needsPrefix = folders.some(f => window.location.pathname.includes('/' + f + '/'));
const prefix = needsPrefix ? '../' : '';


// Attendre que le DOM soit prêt
document.addEventListener('DOMContentLoaded', function() {
    // Attendre que le navbar soit injecté
    setTimeout(initNavbar, 100);
});

function initNavbar() {
    const btnMenu = document.getElementById('btn-menu');
    const btnClose = document.getElementById('btn-close-menu');
    const sidebar = document.getElementById('mobile-sidebar');
    const overlay = document.getElementById('mobile-overlay');

    console.log('Navbar elements:', { btnMenu, sidebar, btnClose, overlay });

    if (!btnMenu || !sidebar) {
        console.error('Menu elements not found!');
        return;
    }

    // Ouvrir le menu
    btnMenu.addEventListener('click', function(e) {
        e.preventDefault();
        e.stopPropagation();
        console.log('Menu button clicked!');
        
        sidebar.classList.add('active');
        if (overlay) overlay.classList.add('active');
        document.body.style.overflow = 'hidden';
    });

    // Fermer le menu
    if (btnClose) {
        btnClose.addEventListener('click', function(e) {
            e.preventDefault();
            sidebar.classList.remove('active');
            if (overlay) overlay.classList.remove('active');
            document.body.style.overflow = '';
        });
    }

    // Fermer au clic sur l'overlay
    if (overlay) {
        overlay.addEventListener('click', function() {
            sidebar.classList.remove('active');
            overlay.classList.remove('active');
            document.body.style.overflow = '';
        });
    }

    // Fermer au clic sur un lien
    sidebar.querySelectorAll('a').forEach(function(link) {
        link.addEventListener('click', function() {
            sidebar.classList.remove('active');
            if (overlay) overlay.classList.remove('active');
            document.body.style.overflow = '';
        });
    });

    // Effet scroll sur navbar
    const navbar = document.getElementById('navbar');
    if (navbar) {
        console.log('Navbar found, setting up scroll effect');
        
        // Pages avec fond blanc qui ont besoin du navbar foncé immédiatement
        const whiteBackgroundPages = ['proprietes.html', 'agents.html', 'contact.html', 'a-propos.html', 'calculateur.html', 'login.html', 'inscription.html'];
        const currentPage = window.location.pathname.split('/').pop() || 'index.html';
        const needsDarkNavbar = whiteBackgroundPages.includes(currentPage);
        
        // Vérifier position initiale ou page avec fond blanc
        if (window.pageYOffset > 50 || needsDarkNavbar) {
            navbar.classList.add('scrolled');
            console.log('Added scrolled class (initial or white background page)');
        }
        
        window.addEventListener('scroll', function() {
            if (window.pageYOffset > 50) {
                if (!navbar.classList.contains('scrolled')) {
                    navbar.classList.add('scrolled');
                    console.log('Added scrolled class');
                }
            } else if (!needsDarkNavbar) {
                // Seulement retirer si ce n'est pas une page avec fond blanc
                if (navbar.classList.contains('scrolled')) {
                    navbar.classList.remove('scrolled');
                    console.log('Removed scrolled class');
                }
            }
        }, { passive: true });
    } else {
        console.error('Navbar not found!');
    }

    // Activer le lien courant
    const currentPage = window.location.pathname.split('/').pop() || 'index.html';
    const currentParams = window.location.search;

    document.querySelectorAll('.nav-link').forEach(function(link) {
        const href = link.getAttribute('href');
        if (href === currentPage || (currentPage === 'proprietes.html' && href && href.includes(currentPage))) {
            link.classList.add('active');
        }
    });

    // Bottom nav active state
    const bottomNav = document.getElementById('bottom-nav');
    if (bottomNav) {
        bottomNav.querySelectorAll('.bottom-nav-item').forEach(function(item) {
            const href = item.getAttribute('href');
            let isActive = false;

            if (href === currentPage) {
                isActive = true;
            } else if (currentPage === 'proprietes.html') {
                if (currentParams.includes('type=vente') && href && href.includes('vente')) {
                    isActive = true;
                } else if (currentParams.includes('type=location') && href && href.includes('location')) {
                    isActive = true;
                }
            }

            if (isActive) {
                item.classList.add('active');
            }
        });
    }

    // ── AUTH STATE ──────────────────────────────────────────────────────────
    checkNavbarAuth();
}

// ── Auth: vérifier session et mettre à jour l'interface ──────────────────
async function checkNavbarAuth() {
    const userStr = localStorage.getItem('exper_immo_user');
    if (userStr) {
        try {
            const user = JSON.parse(userStr);
            navbarShowConnected(user.full_name, user.role);
            navbarUpdateUser(user.full_name, user.role);
        } catch (e) {
            navbarShowDisconnected();
        }
    } else {
        navbarShowDisconnected();
    }

    // Bouton déconnexion
    var btnLogout  = document.getElementById('btn-logout');
    var sideLogout = document.getElementById('sidebar-logout');
    function doLogout(e) {
        if (e) e.preventDefault();
        localStorage.removeItem('exper_immo_token');
        localStorage.removeItem('exper_immo_user');
        window.location.href = prefix + 'index.html';
    }
    if (btnLogout)  btnLogout.addEventListener('click', doLogout);
    if (sideLogout) sideLogout.addEventListener('click', doLogout);
}

function navbarShowConnected(name, role) {
    var notConn    = document.getElementById('nav-not-connected');
    var conn       = document.getElementById('nav-connected');
    var sbNotConn  = document.getElementById('sidebar-not-connected');
    var sbConn     = document.getElementById('sidebar-connected');
    var sbMenuConn = document.getElementById('sidebar-menu-connected');

    if (notConn)    notConn.style.display    = 'none';
    if (conn)       conn.style.display       = 'flex';
    if (sbNotConn)  sbNotConn.style.display  = 'none';
    if (sbConn)     sbConn.style.display     = 'block';
    if (sbMenuConn) sbMenuConn.style.display = 'block';
}

function navbarShowDisconnected() {
    var notConn    = document.getElementById('nav-not-connected');
    var conn       = document.getElementById('nav-connected');
    var sbNotConn  = document.getElementById('sidebar-not-connected');
    var sbConn     = document.getElementById('sidebar-connected');
    var sbMenuConn = document.getElementById('sidebar-menu-connected');

    if (notConn)    notConn.style.display    = 'flex';
    if (conn)       conn.style.display       = 'none';
    if (sbNotConn)  sbNotConn.style.display  = 'flex';
    if (sbConn)     sbConn.style.display     = 'none';
    if (sbMenuConn) sbMenuConn.style.display = 'none';
}

function navbarUpdateUser(fullName, role) {
    var initials = (fullName || 'U').split(' ').map(function(n){return n[0]||'';}).join('').toUpperCase().slice(0,2) || 'U';
    var roleLabels = { admin:'Administrateur', proprietaire:'Propriétaire', locataire:'Locataire', gestionnaire:'Gestionnaire', assistante:'Assistante' };
    var roleLabel  = roleLabels[role] || role;

    // Desktop
    var elName   = document.getElementById('nav-user-name');
    var elAvatar = document.getElementById('nav-user-avatar');
    var elDName  = document.getElementById('dropdown-name');
    var elDRole  = document.getElementById('dropdown-role');
    if (elName)   elName.textContent   = fullName;
    if (elAvatar) elAvatar.textContent = initials;
    if (elDName)  elDName.textContent  = fullName;
    if (elDRole)  elDRole.textContent  = roleLabel;

    // Sidebar mobile
    var sbName   = document.getElementById('sidebar-name');
    var sbRole   = document.getElementById('sidebar-role');
    var sbAvatar = document.getElementById('sidebar-avatar');
    if (sbName)   sbName.textContent   = fullName;
    if (sbRole)   sbRole.textContent   = roleLabel;
    if (sbAvatar) sbAvatar.textContent = initials;

    // Menus selon rôle
    var menuProp  = document.getElementById('menu-proprietaire');
    var menuLoc   = document.getElementById('menu-locataire');
    var menuAdmin = document.getElementById('menu-admin');
    var lkProp    = document.getElementById('sidebar-link-proprietaire');
    var lkLoc     = document.getElementById('sidebar-link-locataire');
    var lkAdmin   = document.getElementById('sidebar-link-admin');

    [menuProp,menuLoc,menuAdmin].forEach(function(el){ if(el) el.style.display='none'; });
    [lkProp,lkLoc,lkAdmin].forEach(function(el){ if(el) el.style.display='none'; });

    switch (role) {
        case 'proprietaire':
            if (menuProp) menuProp.style.display = 'block';
            if (lkProp)   lkProp.style.display   = 'flex';
            break;
        case 'locataire':
            if (menuLoc) menuLoc.style.display = 'block';
            if (lkLoc)   lkLoc.style.display   = 'flex';
            break;
        case 'admin':
        case 'assistante':
            if (menuAdmin) menuAdmin.style.display = 'block';
            if (lkAdmin)   lkAdmin.style.display   = 'flex';
            // Admin voit tout
            if (role === 'admin') {
                if (menuProp) menuProp.style.display = 'block';
                if (menuLoc)  menuLoc.style.display  = 'block';
                var adminBtn = document.getElementById('nav-admin-btn');
                if (adminBtn) adminBtn.style.display = 'flex';
            }
            break;
        case 'gestionnaire':
            // Menu spécifique gestionnaire (lien dashboard gestionnaire)
            if (lkAdmin) { lkAdmin.style.display='flex'; lkAdmin.href='gestionnaire/index.html'; lkAdmin.innerHTML='<i data-lucide="layout-dashboard"></i> Dashboard Gestionnaire'; }
            if (menuAdmin) { menuAdmin.style.display='block'; var a=menuAdmin.querySelector('a'); if(a){ a.href='gestionnaire/index.html'; a.innerHTML='<i data-lucide="layout-dashboard"></i> Tableau de bord<span class="nav-admin-badge">Gest.</span>'; } }
            break;
    }

    if (window.lucide) lucide.createIcons();
}
