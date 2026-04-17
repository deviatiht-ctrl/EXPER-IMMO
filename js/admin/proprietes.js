// admin/proprietes.js
import { supabaseClient as supabase } from '../supabase-client.js';

let allProps = [];

document.addEventListener('DOMContentLoaded', async () => {
    await checkAuth();
    setupLogout();
    setupSearch();
    await loadProperties();
    if (typeof lucide !== 'undefined') lucide.createIcons();
});

async function checkAuth() {
    const { data: { user } } = await supabase.auth.getUser();
    if (!user) { window.location.href = '../login.html'; return; }
    const { data: profile } = await supabase.from('profiles').select('role').eq('id', user.id).single();
    if (profile?.role !== 'admin') { window.location.href = '../index.html'; }
}

function setupLogout() {
    document.getElementById('btn-logout')?.addEventListener('click', async function() {
        await supabase.auth.signOut();
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
        renderProps(v ? allProps.filter(function(p){ return p.statut === v; }) : allProps);
    });
    document.getElementById('prop-tbody')?.addEventListener('click', async function(e) {
        var btn = e.target.closest('.btn-delete');
        if (btn && confirm('Supprimer cette propriete ?')) {
            var { error } = await supabase.from('proprietes').delete().eq('id_propriete', btn.dataset.id);
            if (!error) loadProperties();
        }
    });
}

async function loadProperties() {
    var tbody = document.getElementById('prop-tbody');
    try {
        var { data: props, error } = await supabase
            .from('proprietes')
            .select('*, zones(nom)')
            .order('created_at', { ascending: false });
        if (error) throw error;
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
    var STATUT_CLASS = { disponible: 'actif', loue: 'warning', vendu: 'inactive' };
    tbody.innerHTML = props.map(function(p) {
        var mainImg = (p.images && p.images.length > 0) ? p.images[0] : null;
        var price = p.prix_location ? '$' + Number(p.prix_location).toLocaleString('fr-FR') + '/mois' : (p.prix_vente ? '$' + Number(p.prix_vente).toLocaleString('fr-FR') : '&#8212;');
        var imgCell = mainImg
            ? '<img src="' + mainImg + '" class="table-thumb">'
            : '<div style="width:40px;height:40px;border-radius:8px;background:#f1f5f9;display:flex;align-items:center;justify-content:center;"><i data-lucide="image" style="width:16px;"></i></div>';
        return '<tr>' +
            '<td>' + imgCell + '</td>' +
            '<td><strong style="font-size:11px;font-weight:700;color:#C53636;">' + (p.reference || '&#8212;') + '</strong></td>' +
            '<td style="font-weight:600;">' + esc(p.titre || 'N/A') + '</td>' +
            '<td>' + esc((p.zones && p.zones.nom) || p.ville || '&#8212;') + '</td>' +
            '<td><strong>' + price + '</strong></td>' +
            '<td><span class="status-badge ' + (STATUT_CLASS[p.statut] || 'inactive') + '">' + esc(p.statut || '&#8212;') + '</span></td>' +
            '<td>' + (p.vue_count || 0) + '</td>' +
            '<td><div class="action-btns">' +
            '<a href="propriete-form.html?id=' + p.id_propriete + '" class="action-btn edit" title="Modifier"><i data-lucide="edit-2"></i></a>' +
            '<button class="action-btn delete btn-delete" data-id="' + p.id_propriete + '" title="Supprimer"><i data-lucide="trash-2"></i></button>' +
            '</div></td>' +
            '</tr>';
    }).join('');
    if (typeof lucide !== 'undefined') lucide.createIcons();
}

function esc(s) { return String(s || '').replace(/&/g,'&amp;').replace(/</g,'&lt;').replace(/>/g,'&gt;'); }