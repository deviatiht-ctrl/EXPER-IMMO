import { apiClient } from '../api-client.js';

document.addEventListener('DOMContentLoaded', () => {
    checkAuth();
    loadProprietaires();
    loadStats();
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
        const proprietaires = await apiClient.get('/admin/proprietaires').catch(() => []);
        document.getElementById('stat-total').textContent = proprietaires.length || 0;
        document.getElementById('stat-actifs').textContent = proprietaires.filter(p => p.statut === 'actif').length || 0;
        document.getElementById('stat-biens').textContent = '0';
    } catch (err) {
        console.error('Erreur stats:', err);
        document.getElementById('stat-total').textContent = '0';
        document.getElementById('stat-actifs').textContent = '0';
        document.getElementById('stat-biens').textContent = '0';
    }
}

async function loadProprietaires() {
    const tbody = document.getElementById('proprietaires-tbody');
    try {
        const data = await apiClient.get('/admin/proprietaires').catch(() => []);
        
        if (!data || data.length === 0) {
            tbody.innerHTML = '<tr><td colspan="8" style="text-align:center;padding:40px;color:#9ca3af;">Aucun propriétaire trouvé</td></tr>';
            return;
        }
        
        tbody.innerHTML = data.map(p => `
            <tr>
                <td>${p.code || '-'}</td>
                <td>${p.nom || '-'} ${p.prenom || ''}</td>
                <td>${p.telephone || '-'}</td>
                <td>${p.email || '-'}</td>
                <td>${p.nb_biens || 0}</td>
                <td>${p.date_inscription ? new Date(p.date_inscription).toLocaleDateString() : '-'}</td>
                <td><span class="badge badge-${p.statut === 'actif' ? 'success' : 'warning'}">${p.statut || 'actif'}</span></td>
                <td>
                    <button class="btn-icon" onclick="viewProprietaire('${p.id}')"><i data-lucide="eye"></i></button>
                </td>
            </tr>
        `).join('');
        
        if (typeof lucide !== 'undefined') lucide.createIcons();
    } catch (error) {
        console.error('Erreur chargement propriétaires:', error);
        tbody.innerHTML = '<tr><td colspan="8" style="text-align:center;padding:40px;color:#9ca3af;">Erreur de chargement</td></tr>';
    }
}

window.viewProprietaire = function(id) {
    alert('Détails du propriétaire ' + id);
};
