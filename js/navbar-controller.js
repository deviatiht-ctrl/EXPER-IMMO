/**
 * EXPERIMMO - Navbar Controller
 * Gestion navbar + auth state (non-module, utilise Supabase CDN global)
 */

// ── Config Supabase (clé publique anon, sans risque) ──────────────────────
var _SB_URL = 'https://gerkqyydddtjeyfkxuyu.supabase.co';
var _SB_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImdlcmtxeXlkZGR0amV5Zmt4dXl1Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzQ3MjE4ODgsImV4cCI6MjA5MDI5Nzg4OH0.BrlZlFcjRQ39mpbX2vEl7ZxXcWRVC114WlVaXnIBKk4';
var _sb = null;

function getSB() {
    if (!_sb && window.supabase) {
        _sb = window.supabase.createClient(_SB_URL, _SB_KEY);
    }
    return _sb;
}

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
    var sb = getSB();
    if (!sb) return;

    try {
        var result = await sb.auth.getSession();
        var session = result.data && result.data.session;

        if (session && session.user) {
            var userId = session.user.id;
            var profileResult = await sb.from('profiles').select('full_name, role').eq('id', userId).single();
            var profile = profileResult.data;
            if (profile) {
                navbarShowConnected(profile.full_name, profile.role);
                navbarUpdateUser(profile.full_name, profile.role);
            } else {
                navbarShowConnected(session.user.email, 'locataire');
                navbarUpdateUser(session.user.email, 'locataire');
            }
            // Mettre à jour dernière connexion (si jamais elle n'est pas à jour)
            sb.rpc('update_derniere_connexion', { p_user_id: userId }).catch(function(){});
        } else {
            navbarShowDisconnected();
        }
    } catch (err) {
        navbarShowDisconnected();
    }

    // Écouter les changements d'auth
    sb.auth.onAuthStateChange(function(event, session) {
        if (event === 'SIGNED_IN' && session) {
            sb.from('profiles').select('full_name, role').eq('id', session.user.id).single()
                .then(function(r) {
                    var p = r.data || { full_name: session.user.email, role: 'locataire' };
                    navbarShowConnected(p.full_name, p.role);
                    navbarUpdateUser(p.full_name, p.role);
                });
        } else if (event === 'SIGNED_OUT') {
            navbarShowDisconnected();
        }
    });

    // Bouton déconnexion
    var btnLogout  = document.getElementById('btn-logout');
    var sideLogout = document.getElementById('sidebar-logout');
    function doLogout(e) {
        if (e) e.preventDefault();
        getSB().auth.signOut().then(function() {
            window.location.href = 'index.html';
        });
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
