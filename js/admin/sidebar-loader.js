/**
 * EXPER IMMO - Admin Sidebar Loader
 * Unifie la barre latérale et le header sur toutes les pages d'administration
 */

const sidebarHTML = `
    <div class="sidebar-logo">
        <div class="logo-icon">
            <img src="../assets/EXPER IMMO LOGO.png" alt="EXPER IMMO" onerror="this.style.display='none'; this.nextElementSibling.style.display='flex';">
            <i data-lucide="home" style="display:none; color: white;"></i>
        </div>
        <span>EXPER IMMO</span>
    </div>
    
    <nav class="sidebar-nav">
        <a href="dashboard.html" class="nav-link" data-admin-page="dashboard">
            <i data-lucide="layout-dashboard"></i>
            <span>Dashboard</span>
        </a>
        <a href="proprietes.html" class="nav-link" data-admin-page="proprietes">
            <i data-lucide="building-2"></i>
            <span>Propriétés</span>
        </a>
        <a href="proprietaires.html" class="nav-link" data-admin-page="proprietaires">
            <i data-lucide="user-circle"></i>
            <span>Propriétaires</span>
        </a>
        <a href="locataires.html" class="nav-link" data-admin-page="locataires">
            <i data-lucide="users"></i>
            <span>Locataires</span>
        </a>
        <a href="contrats.html" class="nav-link" data-admin-page="contrats">
            <i data-lucide="file-text"></i>
            <span>Contrats</span>
        </a>
        <a href="paiements.html" class="nav-link" data-admin-page="paiements">
            <i data-lucide="credit-card"></i>
            <span>Paiements</span>
        </a>
        <a href="agents.html" class="nav-link" data-admin-page="agents">
            <i data-lucide="briefcase"></i>
            <span>Agents</span>
        </a>
        <a href="contacts.html" class="nav-link" data-admin-page="contacts">
            <i data-lucide="message-square"></i>
            <span>Messages</span>
        </a>
        <a href="statistiques.html" class="nav-link" data-admin-page="statistiques">
            <i data-lucide="bar-chart-3"></i>
            <span>Statistiques</span>
        </a>
        <a href="parametres.html" class="nav-link" data-admin-page="parametres">
            <i data-lucide="settings"></i>
            <span>Paramètres</span>
        </a>
    </nav>
    
    <div class="sidebar-footer">
        <button id="admin-logout">
            <i data-lucide="log-out"></i>
            Déconnexion
        </button>
    </div>
`;

document.addEventListener('DOMContentLoaded', () => {
    const sidebarElement = document.getElementById('admin-sidebar');
    if (sidebarElement) {
        sidebarElement.innerHTML = sidebarHTML;
        
        // Mark active link
        const currentPath = window.location.pathname;
        const page = currentPath.split('/').pop().replace('.html', '');
        const activeLink = sidebarElement.querySelector(`[data-admin-page="${page}"]`);
        if (activeLink) activeLink.classList.add('active');
        
        // Handle Logout
        const btnLogout = document.getElementById('admin-logout');
        if (btnLogout) {
            btnLogout.addEventListener('click', () => {
                localStorage.removeItem('exper_immo_token');
                localStorage.removeItem('exper_immo_user');
                window.location.href = '../login.html';
            });
        }
        
        // Re-run Lucide
        if (typeof lucide !== 'undefined') {
            lucide.createIcons();
        }
    }
});
