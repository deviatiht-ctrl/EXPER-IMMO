import { apiClient } from '../api-client.js';

let allContrats = [];

document.addEventListener('DOMContentLoaded', () => {
    checkAuth();
    loadContrats();
    setupLogout();
    setupFilters();
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

function setupLogout() {
    document.getElementById('btn-logout')?.addEventListener('click', () => {
        localStorage.removeItem('exper_immo_token');
        localStorage.removeItem('exper_immo_user');
        window.location.href = '../login.html';
    });
}

async function loadContrats() {
    const tbody = document.getElementById('contrats-tbody');
    try {
        const data = await apiClient.get('/admin/contrats').catch(() => []);
        allContrats = data || [];

        const now = new Date();
        const in30 = new Date(); in30.setDate(in30.getDate() + 30);

        setEl('stat-total', allContrats.length);
        setEl('stat-actifs', allContrats.filter(c => c.statut === 'actif').length);
        setEl('stat-expiration', allContrats.filter(c => {
            if (!c.date_fin) return false;
            const fin = new Date(c.date_fin);
            return fin >= now && fin <= in30;
        }).length);

        renderTable(allContrats);
    } catch (err) {
        console.error('loadContrats:', err);
        if (tbody) tbody.innerHTML = '<tr><td colspan="9" style="text-align:center;color:red;padding:20px;">Erreur de chargement</td></tr>';
    }
}

function renderTable(data) {
    const tbody = document.getElementById('contrats-tbody');
    if (!tbody) return;
    if (!data || !data.length) {
        tbody.innerHTML = '<tr><td colspan="9" style="text-align:center;padding:40px;color:#9ca3af;">Aucun contrat trouvé</td></tr>';
        return;
    }
    tbody.innerHTML = data.map(c => `<tr>
        <td><strong>${esc(c.code_contrat || c.reference || '-')}</strong></td>
        <td>${esc(c.propriete?.titre || '-')}</td>
        <td>${esc(c.proprietaire?.user?.full_name || '-')}</td>
        <td>${esc(c.locataire?.user?.full_name || '-')}</td>
        <td>${c.date_debut ? c.date_debut.substring(0, 10) : '-'}</td>
        <td>${c.date_fin ? c.date_fin.substring(0, 10) : '-'}</td>
        <td><strong>${c.loyer_mensuel ? Number(c.loyer_mensuel).toLocaleString('fr-FR') + ' HTG' : '-'}</strong></td>
        <td><span class="status-badge ${c.statut === 'actif' ? 'actif' : c.statut === 'expire' ? 'inactive' : 'warning'}">${c.statut || '-'}</span></td>
        <td><div class="action-btns">
            <button class="action-btn view" title="Voir"><i data-lucide="eye"></i></button>
        </div></td>
    </tr>`).join('');
    if (typeof lucide !== 'undefined') lucide.createIcons();
}

function setupFilters() {
    document.getElementById('filter-statut')?.addEventListener('change', function (e) {
        const v = e.target.value;
        renderTable(v ? allContrats.filter(c => c.statut === v) : allContrats);
    });
}

function setEl(id, v) { const e = document.getElementById(id); if (e) e.textContent = v; }
function esc(s) { return String(s || '').replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;'); }
