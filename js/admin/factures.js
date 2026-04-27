import { apiClient } from '../api-client.js';

const tableBody = document.getElementById('factures-table');
const formFacture = document.getElementById('form-facture');

document.addEventListener('DOMContentLoaded', async () => {
    const user = JSON.parse(localStorage.getItem('exper_immo_user') || '{}');
    const token = localStorage.getItem('exper_immo_token');
    
    if (!token || !user.id) {
        window.location.href = '../login.html';
        return;
    }
    
    if (user.role !== 'admin') {
        window.location.href = '../index.html';
        return;
    }

    await loadSelectionData();
    await loadFactures();

    formFacture?.addEventListener('submit', saveFacture);
});

async function loadSelectionData() {
    try {
        // Load Locataires
        const locs = await apiClient.get('/locataires').catch(() => []);
        if (locs) {
            const select = document.getElementById('fac-locataire');
            if (select) {
                select.innerHTML = '<option value="">Choisir...</option>' + 
                    locs.map(l => `<option value="${l.id || l.id_locataire}">${l.prenom || ''} ${l.nom || ''}</option>`).join('');
            }
        }

        // Load Proprietes
        const props = await apiClient.get('/properties').catch(() => []);
        if (props) {
            const select = document.getElementById('fac-propriete');
            if (select) {
                select.innerHTML = '<option value="">Choisir...</option>' + 
                    props.map(p => `<option value="${p.id || p.id_propriete}">${p.titre || p.title}</option>`).join('');
            }
        }
    } catch (e) {
        console.warn('Could not load selection data:', e);
    }
}

async function loadFactures() {
    tableBody.innerHTML = '<tr><td colspan="8" style="text-align: center;">Chargement...</td></tr>';
    
    try {
        // Factures endpoint may not exist yet, show placeholder
        const data = []; // await apiClient.get('/factures').catch(() => []);
        
        if (!data || data.length === 0) {
            tableBody.innerHTML = '<tr><td colspan="8" style="text-align: center;">Aucune facture</td></tr>';
            return;
        }
        
        tableBody.innerHTML = data.map(f => `
            <tr>
                <td>FAC-${String(f.id || f.id_facture).padStart(4,'0')}</td>
                <td>${f.type_facture}</td>
                <td>${f.periode}</td>
                <td>${f.locataire?.prenom || ''} ${f.locataire?.nom || ''}</td>
                <td>${(f.montant || 0).toLocaleString()} ${f.devise || 'HTG'}</td>
                <td><span class="status-badge ${f.statut_facture || f.status}">${f.statut_facture || f.status || 'N/A'}</span></td>
                <td>${new Date(f.date_emission || f.created_at).toLocaleDateString()}</td>
                <td class="actions">
                    <button class="action-btn view" onclick="viewFacture(${(f.id || f.id_facture)})" title="Voir"><i data-lucide="eye"></i></button>
                    <button class="action-btn edit" onclick="editFacture(${(f.id || f.id_facture)})" title="Modifier"><i data-lucide="edit-2"></i></button>
                </td>
            </tr>
        `).join('');
        
        if (typeof lucide !== 'undefined') lucide.createIcons();
    } catch (error) {
        console.error(error);
        tableBody.innerHTML = '<tr><td colspan="8" style="text-align: center; color: #dc2626;">Erreur de chargement</td></tr>';
    }
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
    try {
        await apiClient.post('/factures', data);
        window.closeModal?.('add-facture');
        formFacture?.reset();
        await loadFactures();
    } catch(err) {
        alert("Erreur : " + err.message);
    }
}
