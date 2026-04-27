import CONFIG from '../config.js';
const { createClient } = supabase;
const supabaseClient = createClient(CONFIG.SUPABASE_URL, CONFIG.SUPABASE_ANON_KEY);

let allContrats = [];

document.addEventListener('DOMContentLoaded', async () => {
    const { data: { user } } = await supabaseClient.auth.getUser();
    if (!user) { window.location.href = '../login.html'; return; }

    document.getElementById('btn-logout')?.addEventListener('click', async () => {
        await supabaseClient.auth.signOut();
        window.location.href = '../login.html';
    });

    await loadContrats(user.id);
    setupFilters();
    if (typeof lucide !== 'undefined') lucide.createIcons();
});

async function loadContrats(userId) {
    const tbody = document.getElementById('contrats-tbody');
    try {
        const { data, error } = await supabaseClient
            .from('contrats')
            .select(`
                id_contrat, reference, code_contrat, date_debut, date_fin, loyer_mensuel, statut,
                propriete:proprietes(titre, code_propriete, gestionnaire_responsable),
                locataire:locataires(code_locataire, user:profiles!locataires_user_id_fkey(full_name)),
                proprietaire:proprietaires(code_proprietaire, user:profiles!proprietaires_user_id_fkey(full_name))
            `)
            ;

        allContrats = (data || []).filter(c => c.propriete?.gestionnaire_responsable === userId);

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
