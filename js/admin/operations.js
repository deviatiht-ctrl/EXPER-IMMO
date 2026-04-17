import CONFIG from '../config.js';
const { createClient } = supabase;
const supabaseClient = createClient(CONFIG.SUPABASE_URL, CONFIG.SUPABASE_ANON_KEY);

const tableBody = document.getElementById('operations-table');
const formOperation = document.getElementById('form-operation');
const propSelect = document.getElementById('op-propriete');

document.addEventListener('DOMContentLoaded', async () => {
    const { data: { user } } = await supabaseClient.auth.getUser();
    if (!user) {
        window.location.href = '../login.html';
        return;
    }

    await loadProperties();
    await loadOperations();

    formOperation.addEventListener('submit', saveOperation);
});

async function loadProperties() {
    const { data, error } = await supabaseClient
        .from('proprietes')
        .select('id_propriete, titre, code_propriete')
        .order('titre');
    
    if (data) {
        propSelect.innerHTML = '<option value="">Sélectionner un bien...</option>' + 
            data.map(p => `<option value="${p.id_propriete}">${p.titre} (${p.code_propriete || 'Sans code'})</option>`).join('');
    }
}

async function loadOperations() {
    tableBody.innerHTML = '<tr><td colspan="7" style="text-align: center;">Chargement...</td></tr>';
    
    const { data, error } = await supabaseClient
        .from('operations')
        .select(`
            *,
            proprietes (titre, code_propriete)
        `)
        .order('date_operation', { ascending: false });

    if (error) {
        tableBody.innerHTML = '<tr><td colspan="7" style="text-align: center; color: red;">Erreur de chargement</td></tr>';
        return;
    }

    if (!data || data.length === 0) {
        tableBody.innerHTML = '<tr><td colspan="7" style="text-align: center;">Aucune opération trouvée</td></tr>';
        return;
    }

    tableBody.innerHTML = data.map(op => `
        <tr>
            <td>${new Date(op.date_operation).toLocaleDateString()}</td>
            <td>
                <strong>${op.proprietes?.titre || 'N/A'}</strong><br>
                <small>${op.code_operation || '-'}</small>
            </td>
            <td><span class="type-pill">${op.type_operation}</span></td>
            <td>${op.montant ? op.montant.toLocaleString() + ' HTG' : '-'}</td>
            <td>
                <span class="status-badge ${op.publie_portail ? 'active' : 'inactive'}">
                    ${op.publie_portail ? 'Visible' : 'Masqué'}
                </span>
            </td>
            <td><span class="status-badge ${op.statut_operation}">${op.statut_operation}</span></td>
            <td>
                <div class="action-btns">
                    <button class="action-btn edit" onclick="editOp('${op.id_operation}')"><i data-lucide="edit-2"></i></button>
                    <button class="action-btn delete" onclick="deleteOp('${op.id_operation}')"><i data-lucide="trash-2"></i></button>
                </div>
            </td>
        </tr>
    `).join('');
    
    lucide.createIcons();
}

async function saveOperation(e) {
    e.preventDefault();
    
    const opData = {
        id_propriete: document.getElementById('op-propriete').value,
        type_operation: document.getElementById('op-type').value,
        date_operation: document.getElementById('op-date').value,
        montant: document.getElementById('op-montant').value || 0,
        reference_decision: document.getElementById('op-ref-decision').value,
        remarques: document.getElementById('op-remarques').value,
        publie_portail: document.getElementById('op-publie').checked,
        statut_operation: 'valide'
    };

    const id = document.getElementById('op-id').value;

    let result;
    if (id) {
        result = await supabaseClient.from('operations').update(opData).eq('id_operation', id);
    } else {
        result = await supabaseClient.from('operations').insert([opData]);
    }

    if (result.error) {
        alert("Erreur lors de l'enregistrement : " + result.error.message);
    } else {
        window.closeModal('add-operation');
        formOperation.reset();
        await loadOperations();
    }
}
