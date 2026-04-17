import CONFIG from '../config.js';
const { createClient } = supabase;
const supabaseClient = createClient(CONFIG.SUPABASE_URL, CONFIG.SUPABASE_ANON_KEY);

let allOps = [];
let currentUser = null;

document.addEventListener('DOMContentLoaded', async () => {
    const { data: { user } } = await supabaseClient.auth.getUser();
    if (!user) { window.location.href = '../login.html'; return; }
    currentUser = user;

    document.getElementById('btn-logout')?.addEventListener('click', async () => {
        await supabaseClient.auth.signOut();
        window.location.href = '../login.html';
    });

    await loadBienOptions(user.id);
    await loadOperations(user.id);
    setupEventListeners();
    if (typeof lucide !== 'undefined') lucide.createIcons();
});

async function loadBienOptions(userId) {
    const select = document.getElementById('op-bien');
    if (!select) return;
    const { data } = await supabaseClient
        .from('proprietes')
        .select('id_propriete, titre, code_propriete')
        .eq('gestionnaire_responsable', userId)
        .order('titre');
    select.innerHTML = '<option value="">-- Choisir un bien --</option>' +
        (data || []).map(p => `<option value="${p.id_propriete}">${esc(p.titre)} (${p.code_propriete || '-'})</option>`).join('');
}

async function loadOperations(userId) {
    const tbody = document.getElementById('ops-tbody');
    try {
        const { data, error } = await supabaseClient
            .from('operations')
            .select('*, proprietes(titre, code_propriete, gestionnaire_responsable)')
            .order('date_operation', { ascending: false });

        if (error) throw error;
        allOps = (data || []).filter(op => op.proprietes?.gestionnaire_responsable === userId);
        setEl('count-ops', allOps.length + ' opération(s)');
        renderTable(allOps);
    } catch (err) {
        console.error('loadOperations:', err);
        if (tbody) tbody.innerHTML = '<tr><td colspan="8" style="text-align:center;color:red;padding:20px;">Erreur de chargement</td></tr>';
    }
}

function renderTable(data) {
    const tbody = document.getElementById('ops-tbody');
    if (!tbody) return;
    if (!data || !data.length) {
        tbody.innerHTML = '<tr><td colspan="8" style="text-align:center;padding:40px;color:#9ca3af;">Aucune opération trouvée</td></tr>';
        return;
    }
    tbody.innerHTML = data.map(op => `<tr>
        <td><strong>${esc(op.code_operation || '-')}</strong></td>
        <td>${op.date_operation ? op.date_operation.substring(0, 10) : '-'}</td>
        <td>${esc(op.proprietes?.titre || '-')}</td>
        <td><span class="status-badge inactive">${esc(op.type_operation || '-')}</span></td>
        <td>${op.montant ? Number(op.montant).toLocaleString('fr-FR') + ' HTG' : '-'}</td>
        <td>${esc(op.reference_decision || '-')}</td>
        <td><span class="status-badge ${op.publie_portail ? 'actif' : 'inactive'}">${op.publie_portail ? 'Visible' : 'Masqué'}</span></td>
        <td><div class="action-btns">
            <button class="action-btn edit" onclick="editOp('${op.id_operation}')" title="Modifier"><i data-lucide="edit-2"></i></button>
        </div></td>
    </tr>`).join('');
    if (typeof lucide !== 'undefined') lucide.createIcons();
}

window.editOp = function (id) {
    const op = allOps.find(o => o.id_operation === id);
    if (!op) return;
    setVal('op-date', (op.date_operation || '').substring(0, 10));
    setVal('op-type', op.type_operation || '');
    setVal('op-bien', op.id_propriete || '');
    setVal('op-montant', op.montant || '');
    setVal('op-ref-decision', op.reference_decision || '');
    setVal('op-description', op.remarques || '');
    setVal('op-remarques', op.remarques || '');
    setVal('op-statut-pub', op.publie_portail ? 'publie' : 'brouillon');
    document.getElementById('modal-op').style.display = 'flex';
};

function setupEventListeners() {
    document.getElementById('form-op')?.addEventListener('submit', async (e) => {
        e.preventDefault();
        const opData = {
            id_propriete: getVal('op-bien') || null,
            type_operation: getVal('op-type'),
            date_operation: getVal('op-date'),
            montant: parseFloat(getVal('op-montant')) || 0,
            reference_decision: getVal('op-ref-decision') || null,
            remarques: getVal('op-description') || null,
            publie_portail: getVal('op-statut-pub') === 'publie',
            statut_operation: 'brouillon'
        };
        const { error } = await supabaseClient.from('operations').insert([opData]);
        if (error) { alert('Erreur: ' + error.message); return; }
        document.getElementById('modal-op').style.display = 'none';
        document.getElementById('form-op').reset();
        await loadOperations(currentUser.id);
    });

    document.getElementById('btn-filtrer')?.addEventListener('click', () => {
        const type = getVal('filter-type');
        const statut = getVal('filter-statut');
        const debut = getVal('filter-debut');
        const fin = getVal('filter-fin');
        let filtered = allOps;
        if (type) filtered = filtered.filter(op => op.type_operation === type);
        if (statut) filtered = filtered.filter(op => op.statut_operation === statut);
        if (debut) filtered = filtered.filter(op => op.date_operation >= debut);
        if (fin) filtered = filtered.filter(op => op.date_operation <= fin);
        renderTable(filtered);
    });
}

function setEl(id, v) { const e = document.getElementById(id); if (e) e.textContent = v; }
function setVal(id, v) { const e = document.getElementById(id); if (e) e.value = v; }
function getVal(id) { const e = document.getElementById(id); return e ? e.value.trim() : ''; }
function esc(s) { return String(s || '').replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;'); }
