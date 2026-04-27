import { apiClient } from '../api-client.js';

document.addEventListener('DOMContentLoaded', () => {
    checkAuth();
    loadStats();
    loadRecentDossiers();
    document.getElementById('header-date').textContent = new Date().toLocaleDateString('fr-FR', { weekday: 'long', year: 'numeric', month: 'long', day: 'numeric' });
});

function checkAuth() {
    const user = JSON.parse(localStorage.getItem('exper_immo_user') || '{}');
    const token = localStorage.getItem('exper_immo_token');
    if (!token || !user.id) {
        window.location.href = '../login.html';
        return;
    }
    if (user.role !== 'gestionnaire' && user.role !== 'admin') {
        window.location.href = '../index.html';
    }
}

async function loadStats() {
    try {
        const proprietes = await apiClient.get('/properties').catch(() => []);
        const locataires = await apiClient.get('/locataires').catch(() => []);

        document.getElementById('stat-mes-biens').textContent = proprietes.length || 0;
        document.getElementById('stat-mes-locataires').textContent = locataires.length || 0;
    } catch (error) {
        console.error('Erreur stats:', error);
        document.getElementById('stat-mes-biens').textContent = '0';
        document.getElementById('stat-mes-locataires').textContent = '0';
    }
}

async function loadRecentDossiers() {
    const container = document.getElementById('dossiers-recents');
    if (!container) return;
    
    try {
        const data = await apiClient.get('/properties').catch(() => []);

        if (data && data.length > 0) {
            container.innerHTML = data.slice(0, 5).map(item => `
                <div class="activity-item">
                    <div class="activity-icon" style="background: #dbeafe; color: #2563eb;">
                        <i data-lucide="building-2"></i>
                    </div>
                    <div class="activity-content">
                        <h4>${item.title || item.titre || 'Sans titre'}</h4>
                        <p>Ref: ${item.reference || 'N/A'}</p>
                    </div>
                    <span class="activity-time">${item.created_at ? new Date(item.created_at).toLocaleDateString() : '-'}</span>
                </div>
            `).join('');
            if (typeof lucide !== 'undefined') lucide.createIcons();
        } else {
            container.innerHTML = '<p class="empty-state">Aucun dossier attribué.</p>';
        }
    } catch (error) {
        container.innerHTML = '<p class="empty-state">Erreur de chargement.</p>';
    }
}
