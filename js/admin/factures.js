import CONFIG from '../config.js';
const { createClient } = supabase;
const supabaseClient = createClient(CONFIG.SUPABASE_URL, CONFIG.SUPABASE_ANON_KEY);

const tableBody = document.getElementById('factures-table');
const formFacture = document.getElementById('form-facture');

document.addEventListener('DOMContentLoaded', async () => {
    const { data: { user } } = await supabaseClient.auth.getUser();
    if (!user) {
        window.location.href = '../login.html';
        return;
    }

    await loadSelectionData();
    await loadFactures();

    formFacture.addEventListener('submit', saveFacture);
});

async function loadSelectionData() {
    // Load Locataires
    const { data: locs } = await supabaseClient.from('locataires').select('id_locataire, nom, prenom');
    if (locs) {
        const select = document.getElementById('fac-locataire');
        select.innerHTML = '<option value="">Choisir...</option>' + 
            locs.map(l => `<option value="${l.id_locataire}">${l.prenom || ''} ${l.nom || ''}</option>`).join('');
    }

    // Load Proprietes
    const { data: props } = await supabaseClient.from('proprietes').select('id_propriete, titre');
    if (props) {
        const select = document.getElementById('fac-propriete');
        select.innerHTML = '<option value="">Choisir...</option>' + 
            props.map(p => `<option value="${p.id_propriete}">${p.titre}</option>`).join('');
    }
}

async function loadFactures() {
    tableBody.innerHTML = '<tr><td colspan="8" style="text-align: center;">Chargement...</td></tr>';
    
    const { data, error } = await supabaseClient
        .from('factures')
        .select(`
            *,
            locataires (nom, prenom)
        `)
        ;

    if (error) {
        tableBody.innerHTML = '<tr><td colspan="8" style="text-align: center; color: red;">Erreur</td></tr>';
        return;
    }

    if (!data || data.length === 0) {
        tableBody.innerHTML = '<tr><td colspan="8" style="text-align: center;">Aucune facture</td></tr>';
        return;
    }

    tableBody.innerHTML = data.map(f => `
        <tr>
            <td><strong>${f.code_facture || '-'}</strong></td>
            <td><span class="type-pill">${f.type_facture}</span></td>
            <td>${f.locataires?.prenom} ${f.locataires?.nom}</td>
            <td>${f.periode}</td>
            <td>${f.montant.toLocaleString()} HTG</td>
            <td>${new Date(f.date_echeance).toLocaleDateString()}</td>
            <td><span class="status-badge ${f.statut_facture}">${f.statut_facture}</span></td>
            <td>
                <div class="action-btns">
                    <button class="action-btn edit" title="Payer" onclick="markAsPaid('${f.id_facture}')"><i data-lucide="check-circle"></i></button>
                    <button class="action-btn view" title="Imprimer"><i data-lucide="printer"></i></button>
                </div>
            </td>
        </tr>
    `).join('');
    
    lucide.createIcons();
}

async function saveFacture(e) {
    e.preventDefault();
    
    const data = {
        id_locataire: document.getElementById('fac-locataire').value,
        id_propriete: document.getElementById('fac-propriete').value,
        type_facture: document.getElementById('fac-type').value,
        periode: document.getElementById('fac-periode').value,
        montant: document.getElementById('fac-montant').value,
        date_echeance: document.getElementById('fac-echeance').value,
        statut_facture: 'impaye'
    };

    const { error } = await supabaseClient.from('factures').insert([data]);

    if (error) {
        alert("Erreur : " + error.message);
    } else {
        window.closeModal('add-facture');
        formFacture.reset();
        await loadFactures();
    }
}
