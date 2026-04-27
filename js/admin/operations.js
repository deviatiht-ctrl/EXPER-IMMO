import { apiClient } from '../api-client.js';

const tableBody = document.getElementById('operations-table');
const formOperation = document.getElementById('form-operation');
const propSelect = document.getElementById('op-propriete');

document.addEventListener('DOMContentLoaded', async () => {
    const user = JSON.parse(localStorage.getItem('exper_immo_user') || '{}');
    const token = localStorage.getItem('exper_immo_token');
    if (!token || !user.id) { window.location.href = '../login.html'; return; }
    if (user.role !== 'admin') { window.location.href = '../index.html'; return; }

    await loadProperties();
    await loadOperations();

    formOperation?.addEventListener('submit', saveOperation);
});

async function loadProperties() {
    try {
        const data = await apiClient.get('/properties').catch(() => []);
        if (propSelect) {
            propSelect.innerHTML = '<option value="">Sélectionner un bien...</option>' +
                data.map(p => `<option value="${p.id || p.id_propriete}">${p.title || p.titre} (${p.code_propriete || 'Sans code'})</option>`).join('');
        }
    } catch(e) { console.warn(e); }
}

async function loadOperations() {
    tableBody.innerHTML = '<tr><td colspan="7" style="text-align: center;">Chargement...</td></tr>';
    try {
        // Operations endpoint may not exist yet
        const data = []; // await apiClient.get('/operations').catch(() => []);

        if (!data || data.length === 0) {
            tableBody.innerHTML = '<tr><td colspan="7" style="text-align: center;">Aucune opération trouvée</td></tr>';
            return;
        }

        tableBody.innerHTML = data.map(op => `
            <tr>
                <td>${new Date(op.date_operation).toLocaleDateString()}</td>
                <td>
                    <strong>${op.propriete?.titre || op.propriete?.title || 'N/A'}</strong><br>
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
                        <button class="action-btn edit" onclick="editOp('${op.id || op.id_operation}')"><i data-lucide="edit-2"></i></button>
                        <button class="action-btn delete" onclick="deleteOp('${op.id || op.id_operation}')"><i data-lucide="trash-2"></i></button>
                    </div>
                </td>
            </tr>
        `).join('');
        if (typeof lucide !== 'undefined') lucide.createIcons();
    } catch(error) {
        console.error(error);
        tableBody.innerHTML = '<tr><td colspan="7" style="text-align: center; color: red;">Erreur de chargement</td></tr>';
    }
}

async function saveOperation(e) {
    e.preventDefault();
    const opData = {
        id_propriete: document.getElementById('op-propriete').value,
        type_operation: document.getElementById('op-type').value,
        date_operation: document.getElementById('op-date').value,
        montant: document.getElementById('op-montant').value || 0,
        reference_decision: document.getElementById('op-ref-decision')?.value,
        remarques: document.getElementById('op-remarques')?.value,
        publie_portail: document.getElementById('op-publie')?.checked,
        statut_operation: 'valide'
    };
    const id = document.getElementById('op-id')?.value;
    try {
        if (id) {
            await apiClient.put(`/operations/${id}`, opData);
        } else {
            await apiClient.post('/operations', opData);
        }
        window.closeModal?.('add-operation');
        formOperation.reset();
        await loadOperations();
    } catch(err) {
        alert("Erreur lors de l'enregistrement : " + err.message);
    }
}
