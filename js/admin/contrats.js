import { supabaseClient as supabase } from '../supabase-client.js';

let contrats = [];
let currentContrat = null;

document.addEventListener('DOMContentLoaded', async () => {
    await checkAuth();
    await Promise.all([loadContrats(), loadStats(), populateSelects()]);
    setupEventListeners();
    if (typeof lucide !== 'undefined') lucide.createIcons();
});

async function checkAuth() {
    const { data: { user } } = await supabase.auth.getUser();
    if (!user) { window.location.href = '../login.html'; return; }
}

async function loadContrats() {
    try {
        console.log("Tentative de chargement des contrats...");
        const { data, error } = await supabase
            .from('contrats')
            .select('*, locataire:locataires(user:profiles(full_name, email)), propriete:proprietes(titre)')
            .order('created_at', { ascending: false });
            
        if (error) {
            console.error("Erreur Supabase Contrats:", error);
            throw error;
        }
        
        contrats = data || [];
        renderTable(contrats);
    } catch (err) {
        console.error('loadContrats:', err);
        document.getElementById('contrats-table').innerHTML = '<tr><td colspan="7" style="color:red">Erreur: ' + err.message + '</td></tr>';
    }
}

async function loadStats() {
    try {
        const [{ count: total }, { count: actifs }] = await Promise.all([
            supabase.from('contrats').select('*', { count: 'exact', head: true }),
            supabase.from('contrats').select('*', { count: 'exact', head: true }).eq('statut', 'actif'),
        ]);
        setEl('stat-total-contrats', total || 0);
        setEl('stat-actifs-contrats', actifs || 0);
    } catch (err) { console.error('loadStats:', err); }
}

async function populateSelects() {
    try {
        const [{ data: locs }, { data: props }] = await Promise.all([
            supabase.from('locataires').select('id_locataire, user:profiles(full_name)').order('created_at'),
            supabase.from('proprietes').select('id_propriete, titre').order('titre'),
        ]);
        var selLoc = document.getElementById('ctr-locataire');
        var selProp = document.getElementById('ctr-propriete');
        if (selLoc) (locs || []).forEach(l => {
            var o = document.createElement('option');
            o.value = l.id_locataire;
            o.textContent = l.user?.full_name || l.id_locataire;
            selLoc.appendChild(o);
        });
        if (selProp) (props || []).forEach(p => {
            var o = document.createElement('option');
            o.value = p.id_propriete;
            o.textContent = p.titre || p.id_propriete;
            selProp.appendChild(o);
        });
    } catch(e) { console.error("Error populating selects:", e); }
}

function renderTable(data) {
    const tbody = document.getElementById('contrats-table');
    if (!tbody) return;
    tbody.innerHTML = data.map(c => `
        <tr data-id="${c.id_contrat}">
            <td><strong>${c.reference || '#' + (c.id_contrat||'').substring(0,8)}</strong></td>
            <td>${c.locataire?.user?.full_name || 'N/A'}</td>
            <td>${c.propriete?.titre || 'N/A'}</td>
            <td>${c.date_debut}</td>
            <td><strong>${c.loyer_mensuel}</strong></td>
            <td><span class="status-badge ${c.statut}">${c.statut}</span></td>
            <td>
                <div class="action-btns">
                    <button class="action-btn view" onclick="viewContrat('${c.id_contrat}')"><i data-lucide="eye"></i></button>
                    <button class="action-btn edit" onclick="editContrat('${c.id_contrat}')"><i data-lucide="edit-2"></i></button>
                </div>
            </td>
        </tr>
    `).join('');
    if (typeof lucide !== 'undefined') lucide.createIcons();
}

function setEl(id, v) { var e = document.getElementById(id); if (e) e.textContent = v; }