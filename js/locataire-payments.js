// locataire-payments.js - Locataire Payments Page
import CONFIG from './config.js';
import { showToast, formatPrice } from './utils.js';
import { requireAuth, logout, supabaseClient } from './auth.js';

let currentUser = null;
let locataireId = null;
let allPayments = [];

const initAuth = async () => {
    currentUser = await requireAuth(['locataire']);
    if (!currentUser) return;
    
    const { data: locataire } = await supabaseClient
        .from('locataires')
        .select('id_locataire')
        /* .eq('user_id', currentUser.id) - TODO: filter nan server */
        [0];
    
    locataireId = locataire?.id_locataire;
    
    document.getElementById('user-name').textContent = currentUser.profile?.full_name || 'Locataire';
    document.getElementById('user-avatar').textContent = 
        (currentUser.profile?.full_name || 'L').charAt(0).toUpperCase();
};

const loadPayments = async () => {
    if (!locataireId) return;
    
    try {
        const { data: payments, error } = await supabaseClient
            .from('paiements')
            .select('*')
            /* .eq('locataire_id', locataireId) - TODO: filter nan server */
            
            ;
        
        allPayments = payments || [];
        renderPayments(allPayments);
        updateStats(allPayments);
        
    } catch (error) {
        console.error('Error loading payments:', error);
        showToast('Erreur lors du chargement des paiements', 'error');
    }
};

const renderPayments = (payments) => {
    const tbody = document.getElementById('payments-tbody');
    
    if (!payments || payments.length === 0) {
        tbody.innerHTML = `
            <tr>
                <td colspan="7" class="text-center text-muted">Aucun paiement enregistré</td>
            </tr>
        `;
        return;
    }
    
    tbody.innerHTML = payments.map(p => `
        <tr>
            <td>${String(p.mois).padStart(2, '0')}/${p.annee}</td>
            <td>${formatPrice(p.montant_loyer, p.devise)}</td>
            <td>${formatPrice(p.montant_charges || 0, p.devise)}</td>
            <td><strong>${formatPrice(p.montant_total, p.devise)}</strong></td>
            <td>${p.date_paiement ? new Date(p.date_paiement).toLocaleDateString() : '-'}</td>
            <td>
                <span class="status-badge ${getStatusClass(p.statut)}">
                    ${getStatusLabel(p.statut)}
                </span>
            </td>
            <td>
                ${p.statut === 'en_attente' || p.statut === 'en_retard' ? `
                    <button class="btn-primary btn-sm" onclick="openPaymentModal('${p.id_paiement}', ${p.montant_total})">
                        <i data-lucide="credit-card"></i> Payer
                    </button>
                ` : `
                    <button class="btn-outline btn-sm" onclick="downloadReceipt('${p.id_paiement}')">
                        <i data-lucide="download"></i> Reçu
                    </button>
                `}
            </td>
        </tr>
    `).join('');
    
    lucide.createIcons();
};

const updateStats = (payments) => {
    const payes = payments.filter(p => p.statut === 'paye').length;
    const attente = payments.filter(p => p.statut === 'en_attente').length;
    const retard = payments.filter(p => p.statut === 'en_retard').length;
    
    document.getElementById('stat-payes').textContent = payes;
    document.getElementById('stat-attente').textContent = attente;
    document.getElementById('stat-retard').textContent = retard;
    
    // Get contract info for loyer
    loadContractInfo();
};

const loadContractInfo = async () => {
    if (!locataireId) return;
    
    try {
        const { data: contract, error } = await supabaseClient
            .from('contrats')
            .select('loyer_mensuel, devise, date_fin')
            /* .eq('locataire_id', locataireId) - TODO: filter nan server */
            /* .eq('statut', 'actif') - TODO: filter nan server */
            [0];
        
        if (error || !contract) return;
        
        document.getElementById('stat-loyer').textContent = formatPrice(contract.loyer_mensuel, contract.devise);
        
        // Find next pending payment
        const nextPayment = allPayments.find(p => p.statut === 'en_attente');
        if (nextPayment) {
            document.getElementById('next-payment-card').style.display = 'block';
            document.getElementById('next-amount').textContent = formatPrice(nextPayment.montant_total, nextPayment.devise);
            document.getElementById('next-due-date').textContent = 
                `Échéance: ${new Date(nextPayment.date_echeance).toLocaleDateString()}`;
            document.getElementById('payment-amount-display').value = formatPrice(nextPayment.montant_total, nextPayment.devise);
        }
        
    } catch (error) {
        console.error('Error loading contract:', error);
    }
};

const getStatusClass = (statut) => {
    switch (statut) {
        case 'paye': return 'green';
        case 'en_attente': return 'orange';
        case 'en_retard': return 'red';
        case 'partiel': return 'blue';
        default: return 'gray';
    }
};

const getStatusLabel = (statut) => {
    switch (statut) {
        case 'paye': return 'Payé';
        case 'en_attente': return 'En attente';
        case 'en_retard': return 'En retard';
        case 'partiel': return 'Partiel';
        default: return statut;
    }
};

const filterPayments = () => {
    const annee = document.getElementById('filter-annee').value;
    const statut = document.getElementById('filter-statut').value;
    
    let filtered = allPayments;
    
    if (annee) {
        filtered = filtered.filter(p => p.annee === parseInt(annee));
    }
    
    if (statut) {
        filtered = filtered.filter(p => p.statut === statut);
    }
    
    renderPayments(filtered);
};

const initFilters = () => {
    document.getElementById('filter-annee').addEventListener('change', filterPayments);
    document.getElementById('filter-statut').addEventListener('change', filterPayments);
};

const initPaymentModal = () => {
    document.getElementById('btn-confirm-payment').addEventListener('click', async () => {
        const method = document.querySelector('input[name="payment-method"]:checked').value;
        const notes = document.getElementById('payment-notes').value;
        
        showToast('Redirection vers la page de paiement...', 'info');
        
        // Here you would integrate with your payment provider
        // For now, just close the modal
        document.getElementById('payment-modal').style.display = 'none';
    });
};

const initLogout = () => {
    document.getElementById('btn-logout').addEventListener('click', async (e) => {
        e.preventDefault();
        await logout();
    });
};

// Global functions for onclick handlers
window.openPaymentModal = (paymentId, amount) => {
    document.getElementById('payment-modal').style.display = 'flex';
};

window.closePaymentModal = () => {
    document.getElementById('payment-modal').style.display = 'none';
};

window.downloadReceipt = (paymentId) => {
    showToast('Téléchargement du reçu...', 'info');
    // Implement receipt download logic
};

document.addEventListener('DOMContentLoaded', async () => {
    await initAuth();
    await loadPayments();
    initFilters();
    initPaymentModal();
    initLogout();
});
