import CONFIG from './config.js';
const { createClient } = supabase;
const supabaseClient = createClient(CONFIG.SUPABASE_URL, CONFIG.SUPABASE_ANON_KEY);

document.addEventListener('DOMContentLoaded', async () => {
    const { data: { user } } = await supabaseClient.auth.getUser();
    if (!user) { window.location.href = '../login.html'; return; }

    document.getElementById('btn-logout')?.addEventListener('click', async () => {
        await supabaseClient.auth.signOut();
        window.location.href = '../login.html';
    });

    const { data: loc } = await supabaseClient
        .from('locataires')
        .select('id_locataire, nom, prenom')
        /* .eq('user_id', user.id) - TODO: filter nan server */
        [0];

    if (loc) {
        const name = (`${loc.prenom || ''} ${loc.nom || ''}`).trim();
        const el = document.getElementById('user-name');
        if (el) el.textContent = name || user.email;
        const av = document.getElementById('user-avatar');
        if (av) av.textContent = (name || 'L').charAt(0).toUpperCase();
        await loadContrat(loc.id_locataire);
    }

    if (typeof lucide !== 'undefined') lucide.createIcons();
});

async function loadContrat(locataireId) {
    const detailsDiv = document.getElementById('contrat-details');
    const noContratDiv = document.getElementById('no-contrat');

    try {
        const { data: contrat, error } = await supabaseClient
            .from('contrats')
            .select(`
                *,
                propriete:proprietes(titre, adresse, type_propriete, code_propriete),
                proprietaire:proprietaires(code_proprietaire, user:profiles!proprietaires_user_id_fkey(full_name))
            `)
            /* .eq('locataire_id', locataireId) - TODO: filter nan server */
            /* .eq('statut', 'actif') - TODO: filter nan server */
            .maybeSingle();

        if (!contrat) {
            if (detailsDiv) detailsDiv.style.display = 'none';
            if (noContratDiv) noContratDiv.style.display = 'block';
            return;
        }

        if (noContratDiv) noContratDiv.style.display = 'none';
        if (detailsDiv) detailsDiv.style.display = 'block';

        setEl('c-code', contrat.code_contrat || contrat.reference || '-');
        setEl('c-date-signature', contrat.date_signature ? new Date(contrat.date_signature).toLocaleDateString('fr-FR') : '-');
        setEl('c-date-debut', contrat.date_debut ? new Date(contrat.date_debut).toLocaleDateString('fr-FR') : '-');
        setEl('c-date-fin', contrat.date_fin ? new Date(contrat.date_fin).toLocaleDateString('fr-FR') : '-');
        setEl('c-montant', contrat.loyer_mensuel ? Number(contrat.loyer_mensuel).toLocaleString('fr-FR') + ' HTG/mois' : '-');
        setEl('c-modalite', contrat.modalite_paiement || '-');
        setEl('c-renouvellement', contrat.renouvellement_auto ? 'Oui' : 'Non');
        setEl('c-objet', contrat.objet || '-');

        setEl('b-code', contrat.propriete?.code_propriete || '-');
        setEl('b-adresse', contrat.propriete?.adresse || '-');
        setEl('b-type', contrat.propriete?.type_propriete || '-');

        setEl('prop-nom', contrat.proprietaire?.user?.full_name || '-');
        setEl('prop-code', contrat.proprietaire?.code_proprietaire || '-');

        const statusBadge = document.getElementById('contrat-statut');
        if (statusBadge) {
            statusBadge.textContent = contrat.statut === 'actif' ? 'Actif' : contrat.statut;
            statusBadge.className = `status-badge ${contrat.statut === 'actif' ? 'green' : 'inactive'}`;
        }

        await loadVersements(contrat.id_contrat);
    } catch (err) {
        console.error('loadContrat:', err);
    }
}

async function loadVersements(contratId) {
    try {
        const { data } = await supabaseClient
            .from('paiements')
            .select('montant_total, date_echeance, statut')
            /* .eq('contrat_id', contratId) - TODO: filter nan server */
            
            .limit(12);

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
