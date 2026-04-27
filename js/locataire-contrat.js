import { apiClient } from './api-client.js';

document.addEventListener('DOMContentLoaded', async () => {
    const user = JSON.parse(localStorage.getItem('exper_immo_user') || '{}');
    const token = localStorage.getItem('exper_immo_token');
    if (!token || !user.id) { window.location.href = '../login.html'; return; }
    if (user.role !== 'locataire' && user.role !== 'admin') { window.location.href = '../index.html'; return; }

    document.getElementById('btn-logout')?.addEventListener('click', () => {
        localStorage.removeItem('exper_immo_token');
        localStorage.removeItem('exper_immo_user');
        window.location.href = '../login.html';
    });

    const name = (`${user.prenom || ''} ${user.nom || ''}`).trim() || user.email || 'Locataire';
    const el = document.getElementById('user-name');
    if (el) el.textContent = name;
    const av = document.getElementById('user-avatar');
    if (av) av.textContent = name.charAt(0).toUpperCase();

    const locId = user.locataire_id || user.id;
    await loadContrat(locId);

    if (typeof lucide !== 'undefined') lucide.createIcons();
});

async function loadContrat(locataireId) {
    const detailsDiv = document.getElementById('contrat-details');
    const noContratDiv = document.getElementById('no-contrat');

    try {
        const contrats = await apiClient.get('/admin/contrats').catch(() => []);
        const contrat = contrats.find(c => c.locataire_id === locataireId && c.statut === 'actif') || contrats.find(c => c.locataire_id === locataireId);

        if (!contrat) {
            if (detailsDiv) detailsDiv.style.display = 'none';
            if (noContratDiv) noContratDiv.style.display = 'block';
            return;
        }

        if (noContratDiv) noContratDiv.style.display = 'none';
        if (detailsDiv) detailsDiv.style.display = 'block';

        setEl('c-code', contrat.code_contrat || contrat.reference || String(contrat.id || '-'));
        setEl('c-date-signature', contrat.date_signature ? new Date(contrat.date_signature).toLocaleDateString('fr-FR') : '-');
        setEl('c-date-debut', contrat.date_debut ? new Date(contrat.date_debut).toLocaleDateString('fr-FR') : '-');
        setEl('c-date-fin', contrat.date_fin ? new Date(contrat.date_fin).toLocaleDateString('fr-FR') : '-');
        setEl('c-montant', contrat.loyer_mensuel ? Number(contrat.loyer_mensuel).toLocaleString('fr-FR') + ' HTG/mois' : '-');
        setEl('c-modalite', contrat.modalite_paiement || '-');
        setEl('c-renouvellement', contrat.renouvellement_auto ? 'Oui' : 'Non');
        setEl('c-objet', contrat.objet || '-');

        const prop = contrat.propriete || contrat.property || {};
        setEl('b-code', prop.code_propriete || '-');
        setEl('b-adresse', prop.adresse || prop.address || '-');
        setEl('b-type', prop.type_propriete || '-');
        setEl('prop-nom', contrat.proprietaire?.nom || '-');
        setEl('prop-code', contrat.proprietaire?.code_proprietaire || '-');

        const statusBadge = document.getElementById('contrat-statut');
        if (statusBadge) {
            statusBadge.textContent = contrat.statut === 'actif' ? 'Actif' : contrat.statut;
            statusBadge.className = `status-badge ${contrat.statut === 'actif' ? 'green' : 'inactive'}`;
        }

        await loadVersements(contrat.id || contrat.id_contrat);
    } catch (err) {
        console.error('loadContrat:', err);
    }
}

async function loadVersements(contratId) {
    try {
        // Paiements endpoint not yet available - show placeholder
        const data = [];

        const tbody = document.getElementById('versements-tbody');
        if (!tbody) return;

        if (!data || !data.length) {
            tbody.innerHTML = '<tr><td colspan="4" class="text-center" style="padding:20px;color:var(--text-muted);">Aucun versement enregistré</td></tr>';
            return;
        }

        tbody.innerHTML = data.map((p, i) => `
            <tr>
                <td>${i + 1}</td>
                <td><strong>${p.montant_total ? Number(p.montant_total).toLocaleString('fr-FR') + ' HTG' : '-'}</strong></td>
                <td>${p.date_echeance ? new Date(p.date_echeance).toLocaleDateString('fr-FR') : '-'}</td>
                <td><span class="status-badge ${p.statut === 'paye' ? 'green' : p.statut === 'en_retard' ? 'red' : 'orange'}">
                    ${p.statut === 'paye' ? 'Payé' : p.statut === 'en_retard' ? 'En retard' : 'En attente'}
                </span></td>
            </tr>
        `).join('');

        if (typeof lucide !== 'undefined') lucide.createIcons();
    } catch (err) {
        console.error('loadVersements:', err);
    }
}

function setEl(id, v) { const e = document.getElementById(id); if (e) e.textContent = v; }
