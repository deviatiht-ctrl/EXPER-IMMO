import apiClient from '../api-client.js';

let contrats = [];

document.addEventListener('DOMContentLoaded', async () => {
    checkAuth();
    await Promise.all([loadContrats(), loadStats(), populateProprietes()]);
    setupContratForm();
    if (typeof lucide !== 'undefined') lucide.createIcons();
});

function checkAuth() {
    const userStr = localStorage.getItem('exper_immo_user');
    if (!userStr) { window.location.href = '../login.html'; return; }
    const user = JSON.parse(userStr);
    if (user.role !== 'admin') { window.location.href = '../index.html'; }
}

async function loadContrats() {
    const tbody = document.getElementById('contrats-table');
    if (tbody) tbody.innerHTML = '<tr><td colspan="7" style="text-align:center">Chargement...</td></tr>';
    try {
        contrats = await apiClient.get('/admin/contrats') || [];
        renderTable(contrats);
    } catch (err) {
        console.error('loadContrats:', err);
        if (tbody) tbody.innerHTML = `<tr><td colspan="7" style="color:red">Erreur: ${err.message}</td></tr>`;
    }
}

async function loadStats() {
    try {
        const total  = contrats.length;
        const actifs = contrats.filter(c => c.statut === 'actif').length;
        setEl('stat-total-contrats',  total);
        setEl('stat-actifs-contrats', actifs);
    } catch (err) { console.error('loadStats:', err); }
}

async function populateProprietes() {
    const sel = document.getElementById('ctr-propriete');
    if (!sel) return;
    try {
        const props = await apiClient.get('/properties') || [];
        props.forEach(p => {
            const o = document.createElement('option');
            o.value = p.id;
            o.textContent = p.titre || p.id;
            sel.appendChild(o);
        });
    } catch (e) { console.warn('populateProprietes:', e); }
}

function renderTable(data) {
    const tbody = document.getElementById('contrats-table');
    if (!tbody) return;
    if (!data.length) {
        tbody.innerHTML = '<tr><td colspan="7" style="text-align:center;padding:40px;color:#64748b;">Aucun contrat trouvé</td></tr>';
        return;
    }
    const statusColors = { actif:'#16a34a', expire:'#dc2626', resilie:'#f59e0b' };
    tbody.innerHTML = data.map(c => {
        const color = statusColors[c.statut] || '#64748b';
        return `<tr>
            <td><strong>${esc(c.reference || 'N/A')}</strong></td>
            <td>${esc(c.nom_proprietaire || 'N/A')}</td>
            <td>${esc(c.nom_locataire || 'N/A')}</td>
            <td>${esc(c.propriete_titre || '—')}</td>
            <td><strong>${Number(c.loyer_mensuel||0).toLocaleString('fr-FR')} ${c.devise||'HTG'}</strong></td>
            <td><span style="background:${color}20;color:${color};padding:3px 10px;border-radius:20px;font-size:12px;font-weight:600;">${c.statut}</span></td>
            <td>
                <div class="action-btns">
                    <button class="action-btn view" onclick="showCodes('${esc(c.code_proprietaire||'')}','${esc(c.code_locataire||'')}','${esc(c.nom_proprietaire||'')}','${esc(c.nom_locataire||'')}')" title="Voir les codes">
                        <i data-lucide="key"></i>
                    </button>
                </div>
            </td>
        </tr>`;
    }).join('');
    if (typeof lucide !== 'undefined') lucide.createIcons();
}

function setupContratForm() {
    const form = document.getElementById('contrat-form');
    if (!form) return;
    form.addEventListener('submit', async (e) => {
        e.preventDefault();
        const btn = form.querySelector('button[type="submit"]');
        btn.disabled = true;
        btn.textContent = 'Création en cours...';
        try {
            const payload = {
                nom_proprietaire:   document.getElementById('ctr-nom-prop')?.value.trim()  || '',
                email_proprietaire: document.getElementById('ctr-email-prop')?.value.trim() || '',
                nom_locataire:      document.getElementById('ctr-nom-loc')?.value.trim()   || '',
                email_locataire:    document.getElementById('ctr-email-loc')?.value.trim() || '',
                propriete_id:       document.getElementById('ctr-propriete')?.value        || null,
                loyer_mensuel:      parseFloat(document.getElementById('ctr-loyer')?.value) || 0,
                devise:             document.getElementById('ctr-devise')?.value            || 'HTG',
                caution:            parseFloat(document.getElementById('ctr-caution')?.value) || 0,
                date_debut:         document.getElementById('ctr-date-debut')?.value       || '',
                date_fin:           document.getElementById('ctr-date-fin')?.value         || '',
                notes:              document.getElementById('ctr-notes')?.value            || '',
            };
            const res = await apiClient.post('/admin/contrats', payload);
            closeModal('add-contrat');
            form.reset();
            await loadContrats();
            // Show the generated codes
            showCodes(res.code_proprietaire, res.code_locataire, payload.nom_proprietaire, payload.nom_locataire);
        } catch (err) {
            alert('Erreur: ' + err.message);
        } finally {
            btn.disabled = false;
            btn.textContent = 'Créer le contrat';
        }
    });
}

window.showCodes = (codeProp, codeLoc, nomProp, nomLoc) => {
    const modal = document.getElementById('codes-modal');
    if (!modal) return;
    const el = (id) => document.getElementById(id);
    if (el('code-prop-val'))  el('code-prop-val').textContent  = codeProp || 'N/A';
    if (el('code-loc-val'))   el('code-loc-val').textContent   = codeLoc  || 'N/A';
    if (el('code-prop-name')) el('code-prop-name').textContent = nomProp  || '';
    if (el('code-loc-name'))  el('code-loc-name').textContent  = nomLoc   || '';
    modal.style.display = 'flex';
};

window.copyCode = (id) => {
    const el = document.getElementById(id);
    if (!el) return;
    navigator.clipboard.writeText(el.textContent).then(() => {
        if (window.showToast) window.showToast('Code copié !', 'success');
    });
};

window.openModal  = (id) => { const m = document.getElementById(id); if (m) m.style.display = 'flex'; };
window.closeModal = (id) => { const m = document.getElementById(id); if (m) m.style.display = 'none'; };

function setEl(id, v) { const e = document.getElementById(id); if (e) e.textContent = v; }
function esc(s) { return String(s||'').replace(/&/g,'&amp;').replace(/</g,'&lt;').replace(/>/g,'&gt;'); }