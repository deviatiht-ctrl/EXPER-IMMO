import { apiClient } from '../api-client.js';

let allLocataires = [];

document.addEventListener('DOMContentLoaded', () => {
    checkAuth();
    loadLocataires();
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

async function loadLocataires() {
    const tbody = document.getElementById('locataires-tbody');
    try {
        const data = await apiClient.get('/locataires').catch(() => []);
        allLocataires = data || [];

        setEl('stat-total', allLocataires.length);
        setEl('stat-contrats', '0');
        setEl('stat-retards', '0');

        renderTable(allLocataires);
    } catch (err) {
        console.error('loadLocataires:', err);
        if (tbody) tbody.innerHTML = '<tr><td colspan="8" style="text-align:center;color:red;padding:20px;">Erreur de chargement</td></tr>';
    }
}

function renderTable(data) {
    const tbody = document.getElementById('locataires-tbody');
    if (!tbody) return;
    if (!data || !data.length) {
        tbody.innerHTML = '<tr><td colspan="8" style="text-align:center;padding:40px;color:#9ca3af;">Aucun locataire trouvé</td></tr>';
        return;
    }
    tbody.innerHTML = data.map(l => {
        const name = l.user?.full_name || (`${l.prenom || ''} ${l.nom || ''}`).trim() || 'N/A';
        return `<tr>
            <td><strong style="color:#7c3aed;">${esc(l.code_locataire || '-')}</strong></td>
            <td>${esc(name)}</td>
            <td>${esc(l.user?.phone || 'N/A')}</td>
            <td>${esc(l.user?.email || 'N/A')}</td>
            <td>-</td>
            <td>-</td>
            <td><span class="status-badge actif">Actif</span></td>
            <td><div class="action-btns">
                <button class="action-btn view" title="Voir"><i data-lucide="eye"></i></button>
            </div></td>
        </tr>`;
    }).join('');
    if (typeof lucide !== 'undefined') lucide.createIcons();
}

function setupFilters() {
    document.getElementById('search-loc')?.addEventListener('input', function (e) {
        const q = e.target.value.toLowerCase();
        document.querySelectorAll('#locataires-tbody tr').forEach(r => {
            r.style.display = r.textContent.toLowerCase().includes(q) ? '' : 'none';
        });
    });
}

function setEl(id, v) { const e = document.getElementById(id); if (e) e.textContent = v; }
function esc(s) { return String(s || '').replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;'); }
