import { apiClient } from '../api-client.js';

let paiements = [];
let currentPaiement = null;

document.addEventListener('DOMContentLoaded', async () => {
    await checkAuth();
    await Promise.all([loadPaiements(), loadStats()]);
    setupEventListeners();
    if (typeof lucide !== 'undefined') lucide.createIcons();
});

async function checkAuth() {
    const user = JSON.parse(localStorage.getItem('exper_immo_user') || '{}');
    const token = localStorage.getItem('exper_immo_token');
    if (!token || !user.id) { window.location.href = '../login.html'; return; }
    if (user.role !== 'admin') { window.location.href = '../index.html'; }
}

async function loadPaiements() {
    try {
        const data = await apiClient.get('/paiements');
        paiements = data || [];
        renderTable(paiements);
    } catch (err) {
        console.error('loadPaiements:', err);
        showToast('Erreur de chargement des paiements', 'error');
    }
}

async function loadStats() {
    try {
        const stats = await apiClient.get('/paiements/stats');
        setEl('stat-revenus-pay', stats.revenus_mois + ' ' + stats.devise);
        setEl('stat-payes', stats.payes || 0);
        setEl('stat-attente-pay', stats.en_attente || 0);
        setEl('stat-retard-pay', stats.en_retard || 0);
    } catch (err) { 
        console.error('loadStats:', err); 
    }
}

function renderTable(data) {
    const tbody = document.getElementById('paiements-table');
    if (!tbody) return;
    if (!data.length) {
        tbody.innerHTML = '<tr><td colspan="8" style="text-align:center;padding:50px;color:#64748b;">Aucun paiement trouvé</td></tr>';
        return;
    }
    const LABELS = { paye: 'Payé', en_attente: 'En attente', en_retard: 'En retard', annule: 'Annulé' };
    tbody.innerHTML = data.map(function(p) {
        var label = LABELS[p.statut] || p.statut;
        return '<tr data-id="' + p.id + '">' +
            '<td><strong>' + esc(p.id.substring(0,8)) + '</strong></td>' +
            '<td>' + esc(p.contrat_id ? p.contrat_id.substring(0,8) : 'N/A') + '</td>' +
            '<td><strong>' + fmtNum(p.montant || 0) + ' ' + esc(p.devise || 'HTG') + '</strong></td>' +
            '<td>' + (p.date_echeance || '').substring(0,10) + '</td>' +
            '<td>' + (p.date_paiement || '—').substring(0,10) + '</td>' +
            '<td><span class="status-badge ' + esc(p.statut) + '">' + label + '</span></td>' +
            '<td><div class="action-btns">' +
            '<button class="action-btn view" onclick="viewPaiement(\'' + p.id + '\')" title="Voir"><i data-lucide="eye"></i></button>' +
            '<button class="action-btn edit" onclick="editPaiement(\'' + p.id + '\')" title="Modifier"><i data-lucide="edit-2"></i></button>' +
            '</div></td></tr>';
    }).join('');
    if (typeof lucide !== 'undefined') lucide.createIcons();
}

window.openModal = function(id) {
    var m = document.getElementById(id);
    if (m) { m.classList.add('is-open'); document.body.style.overflow = 'hidden'; }
};
window.closeModal = function(id) {
    var m = document.getElementById(id);
    if (m) { m.classList.remove('is-open'); document.body.style.overflow = ''; }
    currentPaiement = null;
    var f = document.getElementById('paiement-form');
    if (f) f.reset();
    setEl('pay-modal-title', 'Enregistrer un Paiement');
};

window.viewPaiement = function(id) {
    var p = paiements.find(function(x){ return x.id === id; });
    if (!p) return;
    showModal('Paiement — ' + esc(id.substring(0,8)), '<div class="detail-section">' +
        '<div class="detail-row"><strong>ID</strong><span>' + esc(id) + '</span></div>' +
        '<div class="detail-row"><strong>Montant</strong><span><strong>' + fmtNum(p.montant || 0) + ' ' + esc(p.devise || 'HTG') + '</strong></span></div>' +
        '<div class="detail-row"><strong>Échéance</strong><span>' + (p.date_echeance || '').substring(0,10) + '</span></div>' +
        '<div class="detail-row"><strong>Date paiement</strong><span>' + (p.date_paiement || '—').substring(0,10) + '</span></div>' +
        '<div class="detail-row"><strong>Statut</strong><span><span class="status-badge ' + esc(p.statut) + '">' + esc(p.statut) + '</span></span></div>' +
        (p.notes ? '<div class="detail-row"><strong>Notes</strong><span>' + esc(p.notes) + '</span></div>' : '') +
        '</div>');
};

window.editPaiement = function(id) {
    var p = paiements.find(function(x){ return x.id === id; });
    if (!p) return;
    currentPaiement = p;
    setEl('pay-modal-title', 'Modifier le Paiement');
    setVal('pay-montant', p.montant || '');
    setVal('pay-echeance', (p.date_echeance || '').substring(0,10));
    setVal('pay-statut', p.statut || 'en_attente');
    setVal('pay-notes', p.notes || '');
    openModal('add-paiement');
    if (typeof lucide !== 'undefined') lucide.createIcons();
};

window.savePaiement = async function(e) {
    e.preventDefault();
    var btn = document.getElementById('pay-save-btn');
    if (btn) { btn.disabled = true; btn.innerHTML = '<span class="spinner-small"></span> Enregistrement...'; }
    try {
        var payData = {
            montant: parseFloat(getVal('pay-montant')) || 0,
            devise: 'HTG',
            date_echeance: getVal('pay-echeance'),
            statut: getVal('pay-statut'),
            notes: getVal('pay-notes') || null,
        };
        if (payData.statut === 'paye' && !currentPaiement) {
            payData.date_paiement = new Date().toISOString().substring(0,10);
        }
        if (currentPaiement) {
            await apiClient.put('/paiements/' + currentPaiement.id, payData);
            showToast('Paiement mis à jour', 'success');
        } else {
            await apiClient.post('/paiements', payData);
            showToast('Paiement enregistré', 'success');
        }
        closeModal('add-paiement');
        await Promise.all([loadPaiements(), loadStats()]);
    } catch (err) {
        console.error('savePaiement:', err);
        showToast(err.message || 'Erreur lors de l\'enregistrement', 'error');
    } finally {
        if (btn) { btn.disabled = false; btn.innerHTML = '<i data-lucide="save"></i><span>Enregistrer</span>'; if (typeof lucide !== 'undefined') lucide.createIcons(); }
    }
};

function setupEventListeners() {
    document.getElementById('btn-logout')?.addEventListener('click', function() {
        localStorage.removeItem('exper_immo_token');
        localStorage.removeItem('exper_immo_user');
        window.location.href = '../login.html';
    });
    document.getElementById('search-paiements')?.addEventListener('input', function(e) {
        var q = e.target.value.toLowerCase();
        document.querySelectorAll('#paiements-table tr').forEach(function(r) {
            r.style.display = r.textContent.toLowerCase().includes(q) ? '' : 'none';
        });
    });
    document.getElementById('filter-statut-pay')?.addEventListener('change', function(e) {
        var v = e.target.value;
        var filtered = v ? paiements.filter(function(p){ return p.statut === v; }) : paiements;
        renderTable(filtered);
    });
    document.querySelectorAll('.modal').forEach(function(m) {
        m.addEventListener('click', function(e) { if (e.target === m) m.classList.remove('is-open'); });
    });
}

function showToast(msg, type) {
    type = type || 'info';
    var t = document.createElement('div');
    t.className = 'toast toast-' + type;
    t.innerHTML = '<i data-lucide="' + (type==='success'?'check-circle':type==='error'?'alert-circle':'info') + '"></i><span>' + msg + '</span>';
    document.body.appendChild(t);
    if (typeof lucide !== 'undefined') lucide.createIcons();
    setTimeout(function(){ t.remove(); }, 5000);
}

function showModal(title, content) {
    var m = document.createElement('div');
    m.className = 'modal is-open';
    m.innerHTML = '<div class="modal-content"><div class="modal-header"><h3>' + title + '</h3><button class="modal-close" onclick="this.closest(\'.modal\').remove()"><i data-lucide="x"></i></button></div><div class="modal-body">' + content + '</div></div>';
    document.body.appendChild(m);
    if (typeof lucide !== 'undefined') lucide.createIcons();
}

function setEl(id, v) { var e = document.getElementById(id); if (e) e.textContent = v; }
function setVal(id, v) { var e = document.getElementById(id); if (e) e.value = v; }
function getVal(id) { var e = document.getElementById(id); return e ? e.value.trim() : ''; }
function fmtNum(n) { return Number(n).toLocaleString('fr-FR'); }
function esc(s) { return String(s || '').replace(/&/g,'&amp;').replace(/</g,'&lt;').replace(/>/g,'&gt;'); }