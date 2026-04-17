import CONFIG from '../config.js';
const { createClient } = supabase;
const supabaseClient = createClient(CONFIG.SUPABASE_URL, CONFIG.SUPABASE_ANON_KEY);

let allBiens = [];

document.addEventListener('DOMContentLoaded', async () => {
    const { data: { user } } = await supabaseClient.auth.getUser();
    if (!user) { window.location.href = '../login.html'; return; }

    document.getElementById('btn-logout')?.addEventListener('click', async () => {
        await supabaseClient.auth.signOut();
        window.location.href = '../login.html';
    });

    await loadBiens(user.id);
    setupFilters();
    if (typeof lucide !== 'undefined') lucide.createIcons();
});

async function loadBiens(userId) {
    const tbody = document.getElementById('biens-tbody');
    try {
        const { data, error } = await supabaseClient
            .from('proprietes')
            .select('id_propriete, code_propriete, titre, adresse, type_propriete, statut, statut_bien, type_mandat, zones(nom), proprietaire:proprietaires(code_proprietaire, user:profiles!proprietaires_user_id_fkey(full_name))')
            .eq('gestionnaire_responsable', userId)
            .order('created_at', { ascending: false });

        if (error) throw error;
        allBiens = data || [];

        setEl('stat-total', allBiens.length);
        setEl('stat-loues', allBiens.filter(b => b.statut === 'loue').length);
        setEl('stat-disponibles', allBiens.filter(b => b.statut === 'disponible').length);
        setEl('stat-travaux', allBiens.filter(b => b.statut_bien === 'en_travaux' || b.statut_bien === 'construction').length);

        renderTable(allBiens);
    } catch (err) {
        console.error('loadBiens:', err);
        if (tbody) tbody.innerHTML = '<tr><td colspan="8" style="text-align:center;color:red;padding:20px;">Erreur de chargement</td></tr>';
    }
}

function renderTable(data) {
    const tbody = document.getElementById('biens-tbody');
    if (!tbody) return;
    if (!data || !data.length) {
        tbody.innerHTML = '<tr><td colspan="8" style="text-align:center;padding:40px;color:#9ca3af;">Aucun bien trouvé</td></tr>';
        return;
    }
    const STATUT_LABELS = { disponible: 'Disponible', loue: 'Loué', en_gestion: 'En gestion', en_travaux: 'En travaux', vendu: 'Vendu' };
    tbody.innerHTML = data.map(b => `<tr>
        <td><strong style="color:#C53636;">${esc(b.code_propriete || '-')}</strong></td>
        <td>${esc(b.type_propriete || '-')}</td>
        <td>${esc(b.adresse || '-')}</td>
        <td>${esc(b.zones?.nom || '-')}</td>
        <td>${esc(b.proprietaire?.user?.full_name || '-')}</td>
        <td>${esc(b.type_mandat || '-')}</td>
        <td><span class="status-badge ${b.statut === 'loue' ? 'warning' : b.statut === 'disponible' ? 'actif' : 'inactive'}">${STATUT_LABELS[b.statut] || b.statut || '-'}</span></td>
        <td><div class="action-btns">
            <button class="action-btn view" title="Voir"><i data-lucide="eye"></i></button>
        </div></td>
    </tr>`).join('');
    if (typeof lucide !== 'undefined') lucide.createIcons();
}

function setupFilters() {
    document.getElementById('filter-statut')?.addEventListener('change', function (e) {
        const v = e.target.value;
        renderTable(v ? allBiens.filter(b => b.statut === v || b.statut_bien === v) : allBiens);
    });
    document.getElementById('search-bien')?.addEventListener('input', function (e) {
        const q = e.target.value.toLowerCase();
        document.querySelectorAll('#biens-tbody tr').forEach(r => {
            r.style.display = r.textContent.toLowerCase().includes(q) ? '' : 'none';
        });
    });
}

function setEl(id, v) { const e = document.getElementById(id); if (e) e.textContent = v; }
function esc(s) { return String(s || '').replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;'); }
