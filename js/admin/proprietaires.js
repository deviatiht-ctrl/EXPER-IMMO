import { supabaseClient as supabase } from '../supabase-client.js';

let proprietaires = [];

document.addEventListener('DOMContentLoaded', async () => {
    await checkAuth();
    await loadProprietaires();
});

async function checkAuth() {
    const { data: { user } } = await supabase.auth.getUser();
    if (!user) { window.location.href = '../login.html'; return; }
}

async function loadProprietaires() {
    try {
        console.log("Chargement propriétaires...");
        const { data, error } = await supabase
            .from('proprietaires')
            .select('*, profiles:user_id(full_name, email, phone)')
            .order('created_at', { ascending: false });

        if (error) {
            console.error("Erreur Supabase Propriétaires:", error);
            throw error;
        }

        proprietaires = data || [];
        renderTable();
    } catch (err) {
        console.error('loadProprietaires:', err);
        const tbody = document.getElementById('proprietaires-table');
        if (tbody) tbody.innerHTML = '<tr><td colspan="5" style="color:red">Erreur: ' + err.message + '</td></tr>';
    }
}

function renderTable() {
    const tbody = document.getElementById('proprietaires-table');
    if (!tbody) return;
    
    if (proprietaires.length === 0) {
        tbody.innerHTML = '<tr><td colspan="5" style="text-align:center">Aucun propriétaire trouvé</td></tr>';
        return;
    }

    tbody.innerHTML = proprietaires.map(p => `
        <tr data-id="${p.id_proprietaire}">
            <td><strong>${p.profiles?.full_name || 'Inconnu'}</strong></td>
            <td>${p.profiles?.email || 'N/A'}</td>
            <td>${p.profiles?.phone || 'N/A'}</td>
            <td>${p.code_proprietaire || (p.id_proprietaire||'').substring(0,8)}</td>
            <td>
                <div class="action-btns">
                    <button class="action-btn view" onclick="window.viewProprietaire('${p.id_proprietaire}')"><i data-lucide="eye"></i></button>
                    <button class="action-btn edit" onclick="window.editProprietaire('${p.id_proprietaire}')"><i data-lucide="edit-2"></i></button>
                </div>
            </td>
        </tr>
    `).join('');
    if (typeof lucide !== 'undefined') lucide.createIcons();
}

window.viewProprietaire = (id) => { console.log("Voir", id); };
window.editProprietaire = (id) => { console.log("Editer", id); };
