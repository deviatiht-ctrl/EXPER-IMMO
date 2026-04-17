import { supabaseClient as supabase } from '../supabase-client.js';

let paiements = [];
let currentPaiement = null;

document.addEventListener('DOMContentLoaded', async () => {
    await checkAuth();
    await Promise.all([loadPaiements(), loadStats(), populateLocataires(), populateProprietes()]);
    setupEventListeners();
    if (typeof lucide !== 'undefined') lucide.createIcons();
});

async function checkAuth() {
    const { data: { user } } = await supabase.auth.getUser();
    if (!user) { window.location.href = '../login.html'; return; }
    const { data: profile } = await supabase.from('profiles').select('role').eq('id', user.id).single();
    if (profile?.role !== 'admin') { window.location.href = '../index.html'; }
}

async function loadPaiements() {
    try {
        const { data, error } = await supabase
            .from('paiements')
            .select('*, locataire:locataires(user:profiles(full_name, email)), propriete:proprietes(titre)')
            .order('date_echeance', { ascending: false });
        if (error) throw error;
        paiements = data || [];
        renderTable(paiements);
    } catch (err) {
        console.error('loadPaiements:', err);
        showToast('Erreur de chargement des paiements', 'error');
    }
}

async function loadStats() {
    try {
        const now = new Date();
        const firstDay = new Date(now.getFullYear(), now.getMonth(), 1).toISOString().substring(0,10);
        const [{ count: payes }, { count: attente }, { count: retard }] = await Promise.all([
            supabase.from('paiements').select('*', { count: 'exact', head: true }).eq('statut', 'paye'),
            supabase.from('paiements').select('*', { count: 'exact', head: true }).eq('statut', 'en_attente'),
            supabase.from('paiements').select('*', { count: 'exact', head: true }).eq('statut', 'en_retard'),
        ]);
        const { data: revenus } = await supabase
            .from('paiements').select('montant_total').eq('statut', 'paye').gte('date_paiement', firstDay);
        const total = (revenus || []).reduce(function(s, r){ return s + (r.montant_total || 0); }, 0);
        setEl('stat-revenus-pay', '$' + fmtNum(total));
        setEl('stat-payes', payes || 0);
        setEl('stat-attente-pay', attente || 0);
        setEl('stat-retard-pay', retard || 0);
    } catch (err) { console.error('loadStats:', err); }
}

async function populateLocataires() {
    const sel = document.getElementById('pay-locataire');
    if (!sel) return;
    const { data } = await supabase.from('locataires').select('id_locataire, user:profiles(full_name)').order('created_at');
    (data || []).forEach(function(l) {
        var opt = document.createElement('option');
        opt.value = l.id_locataire;
        opt.textContent = (l.user && l.user.full_name) || l.id_locataire;
        sel.appendChild(opt);
    });
}

async function populateProprietes() {
    const sel = document.getElementById('pay-propriete');
    if (!sel) return;
    const { data } = await supabase.from('proprietes').select('id_propriete, titre').order('titre');
    (data || []).forEach(function(p) {
        var opt = document.createElement('option');
        opt.value = p.id_propriete;
        opt.textContent = p.titre || p.id_propriete;
        sel.appendChild(opt);
    });
}

function renderTable(data) {
    const tbody = document.getElementById('paiements-table');
    if (!tbody) return;
    if (!data.length) {
        tbody.innerHTML = '<tr><td colspan="8" style="text-align:center;padding:50px;color:#64748b;">Aucun paiement trouv&#233;</td></tr>';
        return;
    }
    const LABELS = { paye: 'Pay&#233;', en_attente: 'En attente', en_retard: 'En retard', annule: 'Annul&#233;' };
    tbody.innerHTML = data.map(function(p) {
        var name = (p.locataire && p.locataire.user && p.locataire.user.full_name) || 'N/A';
        var prop = (p.propriete && p.propriete.titre) || 'N/A';
        var label = LABELS[p.statut] || p.statut;
        return '<tr data-id="' + p.id_paiement + '">' +
            '<td><strong>' + esc(p.reference || '#' + (p.id_paiement||'').substring(0,8)) + '</strong></td>' +
            '<td>' + esc(name) + '</td>' +
            '<td>' + esc(prop) + '</td>' +
            '<td><strong>$' + fmtNum(p.montant_total || 0) + '</strong></td>' +
            '<td>' + (p.date_echeance || '').substring(0,10) + '</td>' +
            '<td>' + esc(p.methode_paiement || '&#8212;') + '</td>' +
            '<td><span class="status-badge ' + esc(p.statut) + '">' + label + '</span></td>' +
            '<td><div class="action-btns">' +
            '<button class="action-btn view" onclick="viewPaiement(\'' + p.id_paiement + '\')" title="Voir"><i data-lucide="eye"></i></button>' +
            '<button class="action-btn edit" onclick="editPaiement(\'' + p.id_paiement + '\')" title="Modifier"><i data-lucide="edit-2"></i></button>' +
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
    var p = paiements.find(function(x){ return x.id_paiement === id; });
    if (!p) return;
    var name = (p.locataire && p.locataire.user && p.locataire.user.full_name) || 'N/A';
    showModal('Paiement â€” ' + esc(p.reference || id), '<div class="detail-section">' +
        '<div class="detail-row"><strong>R&#233;f&#233;rence</strong><span>' + esc(p.reference || id) + '</span></div>' +
        '<div class="detail-row"><strong>Locataire</strong><span>' + esc(name) + '</span></div>' +
        '<div class="detail-row"><strong>Propri&#233;t&#233;</strong><span>' + esc((p.propriete && p.propriete.titre) || 'N/A') + '</span></div>' +
        '<div class="detail-row"><strong>Montant</strong><span><strong>$' + fmtNum(p.montant_total || 0) + '</strong></span></div>' +
        '<div class="detail-row"><strong>&#201;ch&#233;ance</strong><span>' + (p.date_echeance || '').substring(0,10) + '</span></div>' +
        '<div class="detail-row"><strong>Date paiement</strong><span>' + (p.date_paiement || '&#8212;').substring(0,10) + '</span></div>' +
        '<div class="detail-row"><strong>M&#233;thode</strong><span>' + esc(p.methode_paiement || '&#8212;') + '</span></div>' +
        '<div class="detail-row"><strong>Statut</strong><span><span class="status-badge ' + esc(p.statut) + '">' + esc(p.statut) + '</span></span></div>' +
        (p.notes ? '<div class="detail-row"><strong>Notes</strong><span>' + esc(p.notes) + '</span></div>' : '') +
        '</div>');
};

window.editPaiement = function(id) {
    var p = paiements.find(function(x){ return x.id_paiement === id; });
    if (!p) return;
    currentPaiement = p;
    setEl('pay-modal-title', 'Modifier le Paiement');
    setVal('pay-locataire', p.locataire_id || '');
    setVal('pay-propriete', p.propriete_id || '');
    setVal('pay-montant', p.montant_total || '');
    setVal('pay-echeance', (p.date_echeance || '').substring(0,10));
    setVal('pay-methode', p.methode_paiement || 'virement');
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
            locataire_id: getVal('pay-locataire') || null,
            propriete_id: getVal('pay-propriete') || null,
            montant_total: parseFloat(getVal('pay-montant')) || 0,
            date_echeance: getVal('pay-echeance'),
            methode_paiement: getVal('pay-methode'),
            statut: getVal('pay-statut'),
            notes: getVal('pay-notes') || null,
        };
        if (payData.statut === 'paye' && !currentPaiement) {
            payData.date_paiement = new Date().toISOString().substring(0,10);
        }
        if (currentPaiement) {
            var { error } = await supabase.from('paiements').update(payData).eq('id_paiement', currentPaiement.id_paiement);
            if (error) throw error;
            showToast('Paiement mis &#224; jour', 'success');
        } else {
            var { error: ie } = await supabase.from('paiements').insert([payData]);
            if (ie) throw ie;
            showToast('Paiement enregistr&#233;', 'success');
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
    document.getElementById('btn-logout')?.addEventListener('click', async function() {
        await supabase.auth.signOut();
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