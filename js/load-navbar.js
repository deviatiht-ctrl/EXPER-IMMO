/**
 * EXPER IMMO - Dynamic Navbar Loader
 * Charge le navbar moderne sur toutes les pages
 */

const navbarHTML = `
<!-- NAVBAR MODERNE -->
<nav class="navbar" id="navbar">
    <div class="navbar-inner">
        <!-- Logo -->
        <a href="index.html" class="navbar-logo">
            <img src="assets/EXPER IMMO LOGO.png" alt="EXPERIMMO" onerror="this.style.display='none'; this.nextElementSibling.style.display='flex'; this.nextElementSibling.style.width='42px'; this.nextElementSibling.style.height='42px';">
            <i data-lucide="building-2" style="display:none; width:42px; height:42px;"></i>
            <span>EXPERIMMO</span>
        </a>

        <!-- Navigation Links - Center -->
        <div class="navbar-links">
            <a href="index.html" class="nav-link" data-page="index">Accueil</a>
            <a href="proprietes.html?type=vente" class="nav-link" data-page="proprietes-vente">Acheter</a>
            <a href="proprietes.html?type=location" class="nav-link" data-page="proprietes-location">Louer</a>
            <a href="services.html" class="nav-link" data-page="services">Services</a>
            <a href="a-propos.html" class="nav-link" data-page="a-propos">À propos</a>
            <a href="contact.html" class="nav-link" data-page="contact">Contact</a>
        </div>

        <!-- Right Actions -->
        <div class="navbar-right">
            <!-- Search Button -->
            <button class="nav-icon-btn" id="btn-search-toggle" title="Rechercher">
                <i data-lucide="search"></i>
            </button>

            <!-- Favorites -->
            <button class="nav-icon-btn" id="btn-favoris" title="Mes favoris">
                <i data-lucide="heart"></i>
                <span class="nav-badge" id="fav-count" style="display:none">0</span>
            </button>

            <!-- NOT CONNECTED: Login/Register Buttons -->
            <div id="nav-not-connected" data-auth="visible">
                <a href="login.html" class="nav-cta nav-cta-secondary">
                    <i data-lucide="log-in"></i>
                    <span>Connexion</span>
                </a>
                <a href="inscription.html" class="nav-cta nav-cta-primary">
                    <i data-lucide="user-plus"></i>
                    <span>Inscription</span>
                </a>
            </div>

            <!-- CONNECTED: User Menu -->
            <div class="nav-user-menu" id="nav-connected" data-auth="hidden" style="display:none">
                <button class="nav-user-btn" id="nav-user-toggle">
                    <div class="nav-user-avatar" id="nav-user-avatar">U</div>
                    <span class="nav-user-name" id="nav-user-name">Utilisateur</span>
                    <i data-lucide="chevron-down"></i>
                </button>

                <!-- Dropdown Menu -->
                <div class="nav-dropdown" id="nav-dropdown">
                    <div class="nav-dropdown-header">
                        <strong id="dropdown-name">Utilisateur</strong>
                        <span id="dropdown-role">Locataire</span>
                    </div>

                    <!-- Links for Proprietaire -->
                    <div id="menu-proprietaire" style="display:none">
                        <a href="proprietaire/index.html">
                            <i data-lucide="layout-dashboard"></i> Mon dashboard
                        </a>
                        <a href="proprietaire/mes-proprietes.html">
                            <i data-lucide="building"></i> Mes propriétés
                        </a>
                        <a href="propriete-form.html">
                            <i data-lucide="plus-circle"></i> Ajouter un bien
                        </a>
                    </div>

                    <!-- Links for Locataire -->
                    <div id="menu-locataire" style="display:none">
                        <a href="locataire/index.html">
                            <i data-lucide="layout-dashboard"></i> Mon dashboard
                        </a>
                        <a href="locataire/mes-paiements.html">
                            <i data-lucide="credit-card"></i> Mes paiements
                        </a>
                        <a href="tickets.html">
                            <i data-lucide="ticket"></i> Support
                        </a>
                    </div>

                    <!-- Links for Admin -->
                    <div id="menu-admin" style="display:none">
                        <a href="admin/index.html">
                            <i data-lucide="shield"></i> Administration
                            <span class="nav-admin-badge">Admin</span>
                        </a>
                        <a href="admin/proprietes.html">
                            <i data-lucide="building-2"></i> Gestion propriétés
                        </a>
                        <a href="admin/agents.html">
                            <i data-lucide="users"></i> Gestion agents
                        </a>
                    </div>

                    <!-- Common Links -->
                    <div class="nav-dropdown-divider"></div>
                    <a href="profil.html">
                        <i data-lucide="user-cog"></i> Mon profil
                    </a>
                    <a href="parametres.html">
                        <i data-lucide="settings"></i> Paramètres
                    </a>
                    <div class="nav-dropdown-divider"></div>
                    <a href="#" class="logout" id="btn-logout">
                        <i data-lucide="log-out"></i> Déconnexion
                    </a>
                </div>
            </div>

            <!-- Admin Quick Access (only for admin) -->
            <a href="admin/index.html" class="nav-icon-btn" id="nav-admin-btn" title="Administration" style="display:none">
                <i data-lucide="shield-check"></i>
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
        <a href="index.html" class="bottom-nav-item" data-page="index">
            <i data-lucide="home"></i>
            <span>Accueil</span>
        </a>
        <a href="proprietes.html?type=vente" class="bottom-nav-item" data-page="proprietes-vente">
            <i data-lucide="tag"></i>
            <span>Acheter</span>
        </a>
        <a href="proprietes.html?type=location" class="bottom-nav-item" data-page="proprietes-location">
            <i data-lucide="key"></i>
            <span>Louer</span>
        </a>
        <a href="services.html" class="bottom-nav-item" data-page="services">
            <i data-lucide="briefcase"></i>
            <span>Services</span>
        </a>
        <a href="login.html" class="bottom-nav-item" data-page="connexion" id="bottom-nav-user">
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
            <img src="assets/EXPER IMMO LOGO.png" alt="EXPERIMMO" onerror="this.style.display='none'; this.nextElementSibling.style.display='flex';">
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
            <a href="login.html" class="sidebar-btn sidebar-btn-primary">
                <i data-lucide="log-in"></i> Se connecter
            </a>
            <a href="inscription.html" class="sidebar-btn sidebar-btn-secondary">
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
            <a href="index.html" class="active"><i data-lucide="home"></i> Accueil</a>
            <a href="services.html"><i data-lucide="briefcase"></i> Services</a>
            <a href="proprietes.html?type=vente"><i data-lucide="tag"></i> Acheter</a>
            <a href="proprietes.html?type=location"><i data-lucide="key"></i> Louer</a>
            <a href="a-propos.html"><i data-lucide="info"></i> À propos</a>
            <a href="contact.html"><i data-lucide="mail"></i> Contact</a>

            <div class="mobile-nav-divider"></div>

            <!-- Connected Links -->
            <div id="sidebar-menu-connected" style="display:none">
                <a href="proprietaire/index.html" id="sidebar-link-proprietaire" style="display:none">
                    <i data-lucide="layout-dashboard"></i> Dashboard Propriétaire
                </a>
                <a href="locataire/index.html" id="sidebar-link-locataire" style="display:none">
                    <i data-lucide="layout-dashboard"></i> Dashboard Locataire
                </a>
                <a href="admin/index.html" id="sidebar-link-admin" style="display:none">
                    <i data-lucide="shield"></i> Administration
                </a>
                <a href="profil.html">
                    <i data-lucide="user-cog"></i> Mon profil
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
