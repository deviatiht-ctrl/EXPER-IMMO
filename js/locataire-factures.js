import CONFIG from './config.js';
const { createClient } = supabase;
const supabaseClient = createClient(CONFIG.SUPABASE_URL, CONFIG.SUPABASE_ANON_KEY);

let allFactures = [];
let locataireId = null;

document.addEventListener('DOMContentLoaded', async () => {
    const { data: { user } } = await supabaseClient.auth.getUser();
    if (!user) { window.location.href = '../login.html'; return; }

    document.getElementById('btn-logout')?.addEventListener('click', async () => {
        await supabaseClient.auth.signOut();
        window.location.href = '../login.html';
    });

    const { data: loc } = await supabaseClient
        .from('locataires')
        .select('id_locataire, nom, prenom')
        /* .eq('user_id', user.id) - TODO: filter nan server */
        [0];

    if (loc) {
        locataireId = loc.id_locataire;
        const name = (`${loc.prenom || ''} ${loc.nom || ''}`).trim() || user.email;
        const el = document.getElementById('user-name');
        if (el) el.textContent = name;
        const av = document.getElementById('user-avatar');
        if (av) av.textContent = (name).charAt(0).toUpperCase();
    }

    await loadFactures();
    setupFilters();
    if (typeof lucide !== 'undefined') lucide.createIcons();
});

async function loadFactures() {
    if (!locataireId) return;
    try {
        const { data, error } = await supabaseClient
            .from('factures')
            .select('*')
            /* .eq('id_locataire', locataireId) - TODO: filter nan server */
            ;

        allFactures = data || [];

        setEl('stat-eau', allFactures.filter(f => f.type_facture === 'eau').length);
        setEl('stat-elec', allFactures.filter(f => f.type_facture === 'electricite').length);
        setEl('stat-payees', allFactures.filter(f => f.statut_facture === 'paye').length);
        setEl('stat-dues', allFactures.filter(f => f.statut_facture === 'impaye').length);

        renderTable(allFactures);
    } catch (err) {
        console.error('loadFactures:', err);
    }
}

function renderTable(data) {
    const tbody = document.getElementById('factures-tbody');
    if (!tbody) return;
    if (!data || !data.length) {
        tbody.innerHTML = '<tr><td colspan="8" class="text-center" style="padding:40px;color:var(--text-muted);">Aucune facture trouvée.</td></tr>';
        return;
    }
    tbody.innerHTML = data.map(f => `
        <tr>
            <td><strong>${esc(f.code_facture || '-')}</strong></td>
            <td><span class="status-badge inactive">${esc(f.type_facture || '-')}</span></td>
            <td>${esc(f.periode || '-')}</td>
            <td>${f.date_emission ? new Date(f.date_emission).toLocaleDateString('fr-FR') : '-'}</td>
            <td>${f.date_echeance ? new Date(f.date_echeance).toLocaleDateString('fr-FR') : '-'}</td>
            <td><strong>${f.montant ? Number(f.montant).toLocaleString('fr-FR') + ' HTG' : '-'}</strong></td>
            <td><span class="status-badge ${f.statut_facture === 'paye' ? 'green' : 'red'}">${f.statut_facture === 'paye' ? 'Payée' : 'Impayée'}</span></td>
            <td>${f.statut_facture !== 'paye'
                ? '<button class="btn-primary btn-sm" style="padding:6px 12px;font-size:0.8rem;"><i data-lucide="credit-card"></i> Payer</button>'
                : '<span style="color:var(--success);font-size:0.85rem;">&#10003; Réglée</span>'}
            </td>
        </tr>
    `).join('');
    if (typeof lucide !== 'undefined') lucide.createIcons();
}

function setupFilters() {
    document.getElementById('filter-type')?.addEventListener('change', function (e) {
        const v = e.target.value;
        renderTable(v ? allFactures.filter(f => f.type_facture === v) : allFactures);
    });
}

function setEl(id, v) { const e = document.getElementById(id); if (e) e.textContent = v; }
function esc(s) { return String(s || '').replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;'); }
