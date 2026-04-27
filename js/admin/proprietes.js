// admin/proprietes.js
import { apiClient } from '../api-client.js';

let allProps = [];

document.addEventListener('DOMContentLoaded', async () => {
    await checkAuth();
    setupLogout();
    setupSearch();
    await loadProperties();
    if (typeof lucide !== 'undefined') lucide.createIcons();
});

async function checkAuth() {
    const user = JSON.parse(localStorage.getItem('exper_immo_user') || '{}');
    const token = localStorage.getItem('exper_immo_token');
    if (!token || !user.id) { window.location.href = '../login.html'; return; }
    if (user.role !== 'admin') { window.location.href = '../index.html'; }
}

function setupLogout() {
    document.getElementById('btn-logout')?.addEventListener('click', async function() {
        localStorage.removeItem('exper_immo_token'); localStorage.removeItem('exper_immo_user');
        window.location.href = '../login.html';
    });
}

function setupSearch() {
    document.getElementById('search-proprietes')?.addEventListener('input', function(e) {
        var q = e.target.value.toLowerCase();
        document.querySelectorAll('#prop-tbody tr').forEach(function(r) {
            r.style.display = r.textContent.toLowerCase().includes(q) ? '' : 'none';
        });
    });
    document.getElementById('filter-statut-prop')?.addEventListener('change', function(e) {
        var v = e.target.value;
        renderProps(v ? allProps.filter(function(p){ return p.statut_bien === v; }) : allProps);
    });
    document.getElementById('prop-tbody')?.addEventListener('click', async function(e) {
        var btn = e.target.closest('.btn-delete');
        if (btn && confirm('Supprimer cette propriete ?')) {
            await apiClient.delete('/properties/' + btn.dataset.id).catch(e => console.error(e));
            loadProperties();
        }
    });
}

async function loadProperties() {
    var tbody = document.getElementById('prop-tbody');
    try {
        // Use apiClient to fetch properties from FastAPI backend
        const props = await apiClient.get('/properties').catch(() => []);
        allProps = props || [];
        var countEl = document.getElementById('prop-count');
        if (countEl) countEl.textContent = allProps.length + ' propriete' + (allProps.length !== 1 ? 's' : '') + ' dans le catalogue';
        renderProps(allProps);
    } catch (err) {
        console.error('loadProperties:', err);
        if (tbody) tbody.innerHTML = '<tr><td colspan="8" style="text-align:center;padding:40px;color:#dc2626;">Erreur de chargement</td></tr>';
    }
}

function renderProps(props) {
    var tbody = document.getElementById('prop-tbody');
    if (!tbody) return;
    if (!props.length) {
        tbody.innerHTML = '<tr><td colspan="8" style="text-align:center;padding:50px;color:#64748b;">Aucune propriete trouvee</td></tr>';
        return;
    }
    var STATUT_CLASS = { disponible: 'actif', loue: 'warning', vendu: 'inactive', occupe: 'warning' };
    var API_URL = window.EXPER_API_URL || 'https://exper-immo.onrender.com';
    tbody.innerHTML = props.map(function(p) {
        var images = Array.isArray(p.images) ? p.images : [];
        var mainImg = images.length > 0 ? images[0] : null;
        // Fix relative URLs from backend
        if (mainImg && mainImg.startsWith('/static/')) mainImg = API_URL + mainImg;
        var price = p.prix ? (p.devise || 'USD') + ' ' + Number(p.prix).toLocaleString('fr-FR') : '&#8212;';
        var statut = p.statut_bien || p.statut || '&#8212;';
        var fallbackThumb = 'this.onerror=null;this.style.cssText="width:50px;height:40px;border-radius:6px;background:#f1f5f9;"';
        var imgCell = mainImg
            ? '<img src="' + mainImg + '" class="table-thumb" style="width:50px;height:40px;object-fit:cover;border-radius:6px;" onerror="' + fallbackThumb + '">'
            : '<div style="width:50px;height:40px;border-radius:6px;background:#f1f5f9;display:flex;align-items:center;justify-content:center;"><i data-lucide="image" style="width:16px;"></i></div>';
        return '<tr>' +
            '<td>' + imgCell + '</td>' +
            '<td><strong style="font-size:11px;font-weight:700;color:#C53636;">' + (p.reference || '&#8212;') + '</strong></td>' +
            '<td style="font-weight:600;">' + esc(p.titre || 'N/A') + '</td>' +
            '<td>' + esc(p.ville || p.adresse || '&#8212;') + '</td>' +
            '<td><strong>' + price + '</strong></td>' +
            '<td><span class="status-badge ' + (STATUT_CLASS[statut] || 'inactive') + '">' + esc(statut) + '</span></td>' +
            '<td>' + esc(p.type_bien || p.type_propriete || '&#8212;') + '</td>' +
            '<td><div class="action-btns">' +
            '<a href="propriete-form.html?id=' + p.id + '" class="action-btn edit" title="Modifier"><i data-lucide="edit-2"></i></a>' +
            '<button class="action-btn delete btn-delete" data-id="' + p.id + '" title="Supprimer"><i data-lucide="trash-2"></i></button>' +
            '</div></td>' +
            '</tr>';
    }).join('');
    if (typeof lucide !== 'undefined') lucide.createIcons();
}

function esc(s) { return String(s || '').replace(/&/g,'&amp;').replace(/</g,'&lt;').replace(/>/g,'&gt;'); }