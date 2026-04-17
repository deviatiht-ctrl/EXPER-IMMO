import CONFIG from '../config.js';
const { createClient } = supabase;
const supabaseClient = createClient(CONFIG.SUPABASE_URL, CONFIG.SUPABASE_ANON_KEY);

let allLocataires = [];

document.addEventListener('DOMContentLoaded', async () => {
    const { data: { user } } = await supabaseClient.auth.getUser();
    if (!user) { window.location.href = '../login.html'; return; }

    document.getElementById('btn-logout')?.addEventListener('click', async () => {
        await supabaseClient.auth.signOut();
        window.location.href = '../login.html';
    });

    await loadLocataires(user.id);
    setupFilters();
    if (typeof lucide !== 'undefined') lucide.createIcons();
});

async function loadLocataires(userId) {
    const tbody = document.getElementById('locataires-tbody');
    try {
        const { data, error } = await supabaseClient
            .from('locataires')
            .select('id_locataire, nom, prenom, code_locataire, user:profiles!locataires_user_id_fkey(full_name, email, phone)')
            .eq('gestionnaire_responsable', userId)
            .order('created_at', { ascending: false });

        if (error) throw error;
        allLocataires = data || [];

        const { count: contrats } = await supabaseClient
            .from('contrats').select('*', { count: 'exact', head: true }).eq('statut', 'actif');
        const { count: retards } = await supabaseClient
            .from('paiements').select('*', { count: 'exact', head: true }).eq('statut', 'en_retard');

        setEl('stat-total', allLocataires.length);
        setEl('stat-contrats', contrats || 0);
        setEl('stat-retards', retards || 0);

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
