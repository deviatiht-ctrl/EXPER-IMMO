/**
 * EXPER IMMO - Dynamic Navbar Loader
 * Charge le navbar moderne sur toutes les pages
 */

const folders = ['admin', 'gestionnaire', 'locataire', 'proprietaire', 'properties'];
const currentPath = window.location.pathname;
const needsPrefix = folders.some(f => currentPath.includes('/' + f + '/'));
const prefix = needsPrefix ? '../' : '';

// Role config: dashboard URL, icon, label
const ROLE_CONFIG = {
    admin:        { href: 'admin/dashboard.html',        icon: 'shield',           label: 'Admin',          color: '#C53636' },
    gestionnaire: { href: 'gestionnaire/index.html',     icon: 'settings-2',       label: 'Gestionnaire',   color: '#7c3aed' },
    proprietaire: { href: 'proprietaire/index.html',     icon: 'home',             label: 'Propriétaire',   color: '#0ea5e9' },
    locataire:    { href: 'locataire/index.html',        icon: 'key',              label: 'Locataire',      color: '#10b981' },
};

const navbarHTML = `
<!-- NAVBAR MODERNE -->
<nav class="navbar" id="navbar">
    <div class="navbar-inner">
        <!-- Logo -->
        <a href="${prefix}index.html" class="navbar-logo">
            <img src="${prefix}assets/EXPER IMMO LOGO.png" alt="EXPERIMMO" onerror="this.style.display='none'; this.nextElementSibling.style.display='flex'; this.nextElementSibling.style.width='42px'; this.nextElementSibling.style.height='42px';">
            <i data-lucide="building-2" style="display:none; width:42px; height:42px;"></i>
            <span>EXPERIMMO</span>
        </a>

        <!-- Navigation Links - Center -->
        <div class="navbar-links">
            <a href="${prefix}index.html" class="nav-link" data-page="index">Accueil</a>
            <a href="${prefix}proprietes.html?type=vente" class="nav-link" data-page="proprietes-vente">Acheter</a>
            <a href="${prefix}proprietes.html?type=location" class="nav-link" data-page="proprietes-location">Louer</a>
            <a href="${prefix}services.html" class="nav-link" data-page="services">Services</a>
            <a href="${prefix}a-propos.html" class="nav-link" data-page="a-propos">À propos</a>
            <a href="${prefix}contact.html" class="nav-link" data-page="contact">Contact</a>
        </div>

        <!-- Right Actions -->
        <div class="navbar-right">
            <!-- Search Button -->
            <button class="nav-icon-btn" id="btn-search-toggle" title="Rechercher">
                <i data-lucide="search"></i>
            </button>

            <!-- NOT CONNECTED: Login/Register Buttons -->
            <div id="nav-not-connected" style="display:flex;gap:8px;align-items:center;">
                <a href="${prefix}login.html" class="nav-cta nav-cta-secondary">
                    <i data-lucide="log-in"></i>
                    <span>Connexion</span>
                </a>
                <a href="${prefix}inscription.html" class="nav-cta nav-cta-primary">
                    <i data-lucide="user-plus"></i>
                    <span>Inscription</span>
                </a>
            </div>

            <!-- CONNECTED: Role Dashboard Button (prominent) -->
            <a href="#" id="nav-role-btn" style="display:none;align-items:center;gap:6px;padding:8px 16px;border-radius:50px;font-weight:600;font-size:13px;color:#fff;text-decoration:none;transition:opacity .2s;" title="Mon espace">
                <i data-lucide="layout-dashboard" id="nav-role-icon" style="width:16px;height:16px;"></i>
                <span id="nav-role-label">Dashboard</span>
            </a>

            <!-- CONNECTED: User Avatar + Dropdown -->
            <div class="nav-user-menu" id="nav-connected" style="display:none;position:relative;">
                <button class="nav-user-btn" id="nav-user-toggle" style="display:flex;align-items:center;gap:8px;background:none;border:none;cursor:pointer;padding:4px 8px;border-radius:50px;">
                    <div class="nav-user-avatar" id="nav-user-avatar" style="width:36px;height:36px;border-radius:50%;background:#C53636;color:#fff;display:flex;align-items:center;justify-content:center;font-weight:700;font-size:14px;">U</div>
                    <i data-lucide="chevron-down" style="width:14px;height:14px;color:#64748b;"></i>
                </button>

                <!-- Dropdown Menu -->
                <div class="nav-dropdown" id="nav-dropdown" style="display:none;position:absolute;right:0;top:calc(100% + 8px);background:#fff;border:1px solid #e2e8f0;border-radius:12px;box-shadow:0 10px 40px rgba(0,0,0,.12);min-width:220px;z-index:9999;overflow:hidden;">
                    <div style="padding:16px;background:#f8fafc;border-bottom:1px solid #e2e8f0;">
                        <strong id="dropdown-name" style="display:block;font-size:14px;color:#1e293b;">Utilisateur</strong>
                        <span id="dropdown-role" style="font-size:12px;color:#64748b;"></span>
                    </div>

                    <!-- Links for Proprietaire -->
                    <div id="menu-proprietaire" style="display:none;">
                        <a href="${prefix}proprietaire/index.html" style="display:flex;align-items:center;gap:10px;padding:10px 16px;color:#374151;text-decoration:none;font-size:13px;transition:background .15s;" onmouseover="this.style.background='#f1f5f9'" onmouseout="this.style.background=''">
                            <i data-lucide="layout-dashboard" style="width:15px;"></i> Mon dashboard
                        </a>
                        <a href="${prefix}proprietaire/mes-proprietes.html" style="display:flex;align-items:center;gap:10px;padding:10px 16px;color:#374151;text-decoration:none;font-size:13px;transition:background .15s;" onmouseover="this.style.background='#f1f5f9'" onmouseout="this.style.background=''">
                            <i data-lucide="building" style="width:15px;"></i> Mes propriétés
                        </a>
                    </div>

                    <!-- Links for Locataire -->
                    <div id="menu-locataire" style="display:none;">
                        <a href="${prefix}locataire/index.html" style="display:flex;align-items:center;gap:10px;padding:10px 16px;color:#374151;text-decoration:none;font-size:13px;transition:background .15s;" onmouseover="this.style.background='#f1f5f9'" onmouseout="this.style.background=''">
                            <i data-lucide="layout-dashboard" style="width:15px;"></i> Mon dashboard
                        </a>
                        <a href="${prefix}locataire/mes-paiements.html" style="display:flex;align-items:center;gap:10px;padding:10px 16px;color:#374151;text-decoration:none;font-size:13px;transition:background .15s;" onmouseover="this.style.background='#f1f5f9'" onmouseout="this.style.background=''">
                            <i data-lucide="credit-card" style="width:15px;"></i> Mes paiements
                        </a>
                        <a href="${prefix}tickets.html" style="display:flex;align-items:center;gap:10px;padding:10px 16px;color:#374151;text-decoration:none;font-size:13px;transition:background .15s;" onmouseover="this.style.background='#f1f5f9'" onmouseout="this.style.background=''">
                            <i data-lucide="ticket" style="width:15px;"></i> Support
                        </a>
                    </div>

                    <!-- Links for Gestionnaire -->
                    <div id="menu-gestionnaire" style="display:none;">
                        <a href="${prefix}gestionnaire/index.html" style="display:flex;align-items:center;gap:10px;padding:10px 16px;color:#374151;text-decoration:none;font-size:13px;transition:background .15s;" onmouseover="this.style.background='#f1f5f9'" onmouseout="this.style.background=''">
                            <i data-lucide="settings-2" style="width:15px;"></i> Dashboard Gest.
                        </a>
                    </div>

                    <!-- Links for Admin -->
                    <div id="menu-admin" style="display:none;">
                        <a href="${prefix}admin/dashboard.html" style="display:flex;align-items:center;gap:10px;padding:10px 16px;color:#C53636;font-weight:600;text-decoration:none;font-size:13px;transition:background .15s;" onmouseover="this.style.background='#fef2f2'" onmouseout="this.style.background=''">
                            <i data-lucide="shield" style="width:15px;"></i> Administration
                        </a>
                        <a href="${prefix}admin/proprietes.html" style="display:flex;align-items:center;gap:10px;padding:10px 16px;color:#374151;text-decoration:none;font-size:13px;transition:background .15s;" onmouseover="this.style.background='#f1f5f9'" onmouseout="this.style.background=''">
                            <i data-lucide="building-2" style="width:15px;"></i> Gestion propriétés
                        </a>
                        <a href="${prefix}admin/contrats.html" style="display:flex;align-items:center;gap:10px;padding:10px 16px;color:#374151;text-decoration:none;font-size:13px;transition:background .15s;" onmouseover="this.style.background='#f1f5f9'" onmouseout="this.style.background=''">
                            <i data-lucide="file-text" style="width:15px;"></i> Contrats
                        </a>
                    </div>

                    <!-- Déconnexion -->
                    <div style="border-top:1px solid #e2e8f0;margin-top:4px;">
                        <a href="#" id="btn-logout" style="display:flex;align-items:center;gap:10px;padding:12px 16px;color:#dc2626;text-decoration:none;font-size:13px;font-weight:500;transition:background .15s;" onmouseover="this.style.background='#fef2f2'" onmouseout="this.style.background=''">
                            <i data-lucide="log-out" style="width:15px;"></i> Déconnexion
                        </a>
                    </div>
                </div>
            </div>

            <!-- CONNECTED: Direct Logout Button (always visible) -->
            <a href="#" id="nav-logout-btn" title="Se déconnecter" style="display:none;align-items:center;gap:5px;padding:7px 13px;border-radius:50px;font-weight:600;font-size:12px;color:#dc2626;border:1.5px solid #dc2626;text-decoration:none;transition:all .2s;" onmouseover="this.style.background='#dc2626';this.style.color='#fff'" onmouseout="this.style.background='';this.style.color='#dc2626'">
                <i data-lucide="log-out" style="width:14px;height:14px;"></i>
                <span class="nav-logout-text">Déconnexion</span>
            </a>

            <!-- Mobile Menu Button -->
            <button class="btn-menu-mobile" id="btn-menu">
                <i data-lucide="menu"></i>
            </button>
        </div>
    </div>
</nav>

<!-- BOTTOM NAV — Glassmorphic pill · Telegram style · Phone only -->
<nav class="bottom-nav" id="bottom-nav">
    <div class="bottom-nav-inner">
        <a href="${prefix}index.html" class="bottom-nav-item" data-page="index">
            <i data-lucide="home"></i>
            <span>Accueil</span>
        </a>
        <a href="${prefix}proprietes.html?type=vente" class="bottom-nav-item" data-page="proprietes-vente">
            <i data-lucide="tag"></i>
            <span>Acheter</span>
        </a>
        <a href="${prefix}proprietes.html?type=location" class="bottom-nav-item" data-page="proprietes-location">
            <i data-lucide="key"></i>
            <span>Louer</span>
        </a>
        <a href="${prefix}services.html" class="bottom-nav-item" data-page="services">
            <i data-lucide="briefcase"></i>
            <span>Services</span>
        </a>
        <a href="${prefix}login.html" class="bottom-nav-item" data-page="connexion" id="bottom-nav-user">
            <i data-lucide="user"></i>
            <span>Compte</span>
        </a>
    </div>
</nav>

<!-- MOBILE SIDEBAR -->
<div class="mobile-sidebar-overlay" id="mobile-overlay"></div>
<aside class="mobile-sidebar" id="mobile-sidebar">
    <div class="sidebar-header">
        <div class="navbar-logo">
            <img src="${prefix}assets/EXPER IMMO LOGO.png" alt="EXPERIMMO" onerror="this.style.display='none'; this.nextElementSibling.style.display='flex';">
            <i data-lucide="building-2" style="display:none"></i>
            <span>EXPERIMMO</span>
        </div>
        <button id="btn-close-menu">
            <i data-lucide="x"></i>
        </button>
    </div>

    <div class="sidebar-content">
        <!-- Not Connected -->
        <div class="sidebar-auth" id="sidebar-not-connected">
            <a href="${prefix}login.html" class="sidebar-btn sidebar-btn-primary">
                <i data-lucide="log-in"></i> Se connecter
            </a>
            <a href="${prefix}inscription.html" class="sidebar-btn sidebar-btn-secondary">
                <i data-lucide="user-plus"></i> Créer un compte
            </a>
        </div>

        <!-- Connected -->
        <div class="sidebar-user" id="sidebar-connected" style="display:none">
            <div class="sidebar-user-info">
                <div class="sidebar-user-avatar" id="sidebar-avatar">U</div>
                <div>
                    <strong id="sidebar-name">Utilisateur</strong>
                    <span id="sidebar-role">Locataire</span>
                </div>
            </div>
        </div>

        <nav class="mobile-nav-links">
            <a href="${prefix}index.html" class="active"><i data-lucide="home"></i> Accueil</a>
            <a href="${prefix}services.html"><i data-lucide="briefcase"></i> Services</a>
            <a href="${prefix}proprietes.html?type=vente"><i data-lucide="tag"></i> Acheter</a>
            <a href="${prefix}proprietes.html?type=location"><i data-lucide="key"></i> Louer</a>
            <a href="${prefix}a-propos.html"><i data-lucide="info"></i> À propos</a>
            <a href="${prefix}contact.html"><i data-lucide="mail"></i> Contact</a>

            <div class="mobile-nav-divider"></div>

            <!-- Connected Links -->
            <div id="sidebar-menu-connected" style="display:none">
                <a href="${prefix}admin/dashboard.html" id="sidebar-link-admin" style="display:none">
                    <i data-lucide="shield"></i> Administration
                </a>
                <a href="${prefix}gestionnaire/index.html" id="sidebar-link-gestionnaire" style="display:none">
                    <i data-lucide="settings-2"></i> Dashboard Gestionnaire
                </a>
                <a href="${prefix}proprietaire/index.html" id="sidebar-link-proprietaire" style="display:none">
                    <i data-lucide="home"></i> Dashboard Propriétaire
                </a>
                <a href="${prefix}locataire/index.html" id="sidebar-link-locataire" style="display:none">
                    <i data-lucide="key"></i> Dashboard Locataire
                </a>
                <div class="mobile-nav-divider"></div>
                <a href="#" class="text-danger" id="sidebar-logout">
                    <i data-lucide="log-out"></i> Déconnexion
                </a>
            </div>
        </nav>
    </div>
</aside>
`;

// Insérer le navbar au début du body
document.body.insertAdjacentHTML('afterbegin', navbarHTML);

// ── Active page highlight ─────────────────────────────────────
(function markActivePage() {
    const path = window.location.pathname.split('/').pop() || 'index.html';
    const search = window.location.search;

    // Determine current page key
    let currentPage = path.replace('.html', '');
    if (currentPage === '' || currentPage === 'index') currentPage = 'index';
    if (path === 'proprietes.html' && search.includes('type=vente'))    currentPage = 'proprietes-vente';
    if (path === 'proprietes.html' && search.includes('type=location')) currentPage = 'proprietes-location';

    // Top navbar links
    document.querySelectorAll('.nav-link[data-page]').forEach(link => {
        link.classList.toggle('active', link.dataset.page === currentPage);
    });

    // Bottom nav items
    document.querySelectorAll('.bottom-nav-item[data-page]').forEach(item => {
        item.classList.toggle('active', item.dataset.page === currentPage);
    });
})();

// ── Auth State Handling ─────────────────────────────────────────
document.addEventListener('DOMContentLoaded', () => {
    const token = localStorage.getItem('exper_immo_token');
    const user = JSON.parse(localStorage.getItem('exper_immo_user') || '{}');

    const doLogout = (e) => {
        if (e) e.preventDefault();
        localStorage.removeItem('exper_immo_token');
        localStorage.removeItem('exper_immo_user');
        window.location.href = prefix + 'login.html';
    };

    if (token && user.id) {
        const role = user.role || 'locataire';
        const cfg = ROLE_CONFIG[role] || ROLE_CONFIG['locataire'];

        // ── Show connected UI ──────────────────────────────────
        const el = (id) => document.getElementById(id);
        if (el('nav-not-connected')) el('nav-not-connected').style.display = 'none';
        if (el('nav-connected'))     el('nav-connected').style.display = 'flex';
        if (el('sidebar-not-connected')) el('sidebar-not-connected').style.display = 'none';
        if (el('sidebar-connected'))     el('sidebar-connected').style.display = 'block';
        if (el('sidebar-menu-connected')) el('sidebar-menu-connected').style.display = 'block';

        // ── Role dashboard button (prominent) ──────────────────
        const roleBtn = el('nav-role-btn');
        if (roleBtn) {
            roleBtn.href = prefix + cfg.href;
            roleBtn.style.display = 'flex';
            roleBtn.style.background = cfg.color;
            const iconEl = el('nav-role-icon');
            if (iconEl) iconEl.setAttribute('data-lucide', cfg.icon);
            const labelEl = el('nav-role-label');
            if (labelEl) labelEl.textContent = cfg.label;
        }

        // ── User info ──────────────────────────────────────────
        const fullName = [user.prenom, user.nom].filter(Boolean).join(' ') || user.full_name || user.email || 'Utilisateur';
        const initial = (user.prenom?.[0] || user.nom?.[0] || user.full_name?.[0] || user.email?.[0] || 'U').toUpperCase();
        const roleLabel = { admin: 'Administrateur', gestionnaire: 'Gestionnaire', proprietaire: 'Propriétaire', locataire: 'Locataire' }[role] || role;

        if (el('nav-user-avatar'))  el('nav-user-avatar').textContent = initial;
        if (el('dropdown-name'))    el('dropdown-name').textContent = fullName;
        if (el('dropdown-role'))    { el('dropdown-role').textContent = roleLabel; el('dropdown-role').style.color = cfg.color; }
        if (el('sidebar-avatar'))   el('sidebar-avatar').textContent = initial;
        if (el('sidebar-name'))     el('sidebar-name').textContent = fullName;
        if (el('sidebar-role'))     el('sidebar-role').textContent = roleLabel;

        // ── Role-specific dropdown menus ───────────────────────
        const showMenu = (id) => { const m = el(id); if (m) m.style.display = 'block'; };
        const showSidebar = (id) => { const m = el(id); if (m) m.style.display = 'flex'; };

        if (role === 'admin') {
            showMenu('menu-admin');
            showSidebar('sidebar-link-admin');
        } else if (role === 'gestionnaire') {
            showMenu('menu-gestionnaire');
            showSidebar('sidebar-link-gestionnaire');
        } else if (role === 'proprietaire') {
            showMenu('menu-proprietaire');
            showSidebar('sidebar-link-proprietaire');
        } else if (role === 'locataire') {
            showMenu('menu-locataire');
            showSidebar('sidebar-link-locataire');
        }

        // ── Bottom nav update ──────────────────────────────────
        const bottomNavUser = el('bottom-nav-user');
        if (bottomNavUser) {
            bottomNavUser.href = prefix + cfg.href;
            bottomNavUser.innerHTML = `<i data-lucide="${cfg.icon}"></i><span>${cfg.label}</span>`;
        }

        // ── Dropdown toggle ────────────────────────────────────
        const toggle = el('nav-user-toggle');
        const dropdown = el('nav-dropdown');
        if (toggle && dropdown) {
            toggle.addEventListener('click', (e) => {
                e.stopPropagation();
                const open = dropdown.style.display === 'block';
                dropdown.style.display = open ? 'none' : 'block';
            });
            document.addEventListener('click', () => { if (dropdown) dropdown.style.display = 'none'; });
        }

        // ── Show direct logout button ──────────────────────────
        const navLogoutBtn = el('nav-logout-btn');
        if (navLogoutBtn) navLogoutBtn.style.display = 'flex';

        // ── Logout ─────────────────────────────────────────────
        el('btn-logout')?.addEventListener('click', doLogout);
        el('sidebar-logout')?.addEventListener('click', doLogout);
        navLogoutBtn?.addEventListener('click', doLogout);

    } else {
        // Not logged in - ensure login buttons visible
        const navNC = document.getElementById('nav-not-connected');
        if (navNC) navNC.style.display = 'flex';
    }

    // Re-render lucide icons after DOM changes
    if (typeof lucide !== 'undefined') lucide.createIcons();
});
