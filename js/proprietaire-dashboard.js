// proprietaire-dashboard.js - Proprietaire Portal Logic
import CONFIG from './config.js';
import { showToast, formatPrice } from './utils.js';
import { requireAuth, logout, supabaseClient } from './auth.js';

// ============================================================
// AUTH CHECK
// ============================================================
let currentUser = null;
let proprietaireId = null;

const initAuth = async () => {
    currentUser = await requireAuth(['proprietaire']);
    if (!currentUser) return;
    
    // Get proprietaire ID
    const { data: proprietaire } = await supabaseClient
        .from('proprietaires')
        .select('*')
        .eq('user_id', currentUser.id)
        .single();
    
    proprietaireId = proprietaire?.id_proprietaire;
    
    // Update UI with user info
    document.getElementById('user-name').textContent = currentUser.profile?.full_name || 'Propriétaire';
    document.getElementById('user-avatar').textContent = 
        (currentUser.profile?.full_name || 'P').charAt(0).toUpperCase();
    
    // Last login (from Auth metadata)
    const lastLogin = new Date(currentUser.last_sign_in_at).toLocaleString('fr-FR');
    document.getElementById('last-login').textContent = lastLogin;
    document.getElementById('welcome-title').textContent = `Heureux de vous revoir, ${currentUser.profile?.full_name || 'M.'}`;
};

// ============================================================
// LOAD DASHBOARD STATS CDC 5.2.1
// ============================================================
const loadDashboardStats = async () => {
    if (!proprietaireId) return;
    
    try {
        // Total biens
        const { count: total } = await supabaseClient.from('proprietes').select('*', { count: 'exact', head: true }).eq('proprietaire_id', proprietaireId);
        // En Gestion
        const { count: gestion } = await supabaseClient.from('proprietes').select('*', { count: 'exact', head: true }).eq('proprietaire_id', proprietaireId).eq('statut_bien', 'gestion');
        // En Construction
        const { count: construction } = await supabaseClient.from('proprietes').select('*', { count: 'exact', head: true }).eq('proprietaire_id', proprietaireId).eq('statut_bien', 'construction');
        // Ops récentes (derniers 30 jours)
        const thirtyDaysAgo = new Date();
        thirtyDaysAgo.setDate(thirtyDaysAgo.getDate() - 30);
        const { count: ops } = await supabaseClient.from('operations').select('*', { count: 'exact', head: true }).eq('id_proprietaire', proprietaireId).gte('date_operation', thirtyDaysAgo.toISOString());

        document.getElementById('stat-total-biens').textContent = total || 0;
        document.getElementById('stat-en-gestion').textContent = gestion || 0;
        document.getElementById('stat-en-construction').textContent = construction || 0;
        document.getElementById('stat-ops-recentes').textContent = ops || 0;
        
    } catch (error) {
        console.error('Error loading stats:', error);
    }
};

// ============================================================
// LOAD PROPERTIES
// ============================================================
const loadProperties = async () => {
    if (!proprietaireId) return;
    
    try {
        const { data: properties, error } = await supabaseClient
            .from('proprietes')
            .select('*, zones(nom)')
            .eq('proprietaire_id', proprietaireId)
            .eq('est_actif', true)
            .order('created_at', { ascending: false })
            .limit(3);
        
        if (error) throw error;
        
        const grid = document.getElementById('properties-grid');
        
        if (!properties || properties.length === 0) {
            grid.innerHTML = `
                <div class="empty-state">
                    <i data-lucide="building-2"></i>
                    <h3>Aucune propriété</h3>
                    <p>Vous n'avez pas encore ajouté de propriété.</p>
                    <a href="ajouter-propriete.html" class="btn-primary mt-3">
                        <i data-lucide="plus"></i> Ajouter une propriété
                    </a>
                </div>
            `;
            if (typeof lucide !== 'undefined') lucide.createIcons();
            return;
        }
        
        grid.innerHTML = properties.map(prop => `
            <div class="property-card-mini">
                <img src="${prop.images?.[0] || 'https://images.unsplash.com/photo-1564013799919-ab600027ffc6?auto=format&fit=crop&q=80&w=400'}" 
                     alt="${prop.titre}">
                <div class="property-card-mini-body">
                    <h4>${prop.titre}</h4>
                    <div class="location">
                        <i data-lucide="map-pin"></i>
                        ${prop.zones?.nom || prop.ville}
                    </div>
                    <div class="property-card-mini-stats">
                        <div class="stat">
                            <div class="stat-value">${formatPrice(prop.prix_location || prop.prix_vente || prop.prix, prop.devise)}</div>
                            <div class="stat-label">${prop.type_transaction === 'location' ? '/mois' : ''}</div>
                        </div>
                        <div class="stat">
                            <div class="stat-value">${prop.statut === 'loue' ? 'Loué' : 'Disponible'}</div>
                            <div class="stat-label">Statut</div>
                        </div>
                    </div>
                </div>
            </div>
        `).join('');
        
        if (typeof lucide !== 'undefined') lucide.createIcons();
        
    } catch (error) {
        console.error('Error loading properties:', error);
    }
};

// ============================================================
// LOAD PAYMENTS
// ============================================================
const loadPayments = async () => {
    if (!proprietaireId) return;
    
    try {
        const { data: payments, error } = await supabaseClient
            .from('paiements')
            .select('*, propriete:proprietes!inner(titre, proprietaire_id)')
            .eq('propriete.proprietaire_id', proprietaireId)
            .order('created_at', { ascending: false })
            .limit(5);
        
        if (error) throw error;
        
        const tbody = document.getElementById('finances-tbody');
        
        if (!payments || payments.length === 0) {
            tbody.innerHTML = `
                <tr>
                    <td colspan="4" class="text-center text-muted">Aucun paiement enregistré</td>
                </tr>
            `;
            return;
        }
        
        tbody.innerHTML = payments.map(p => `
            <tr>
                <td>${p.mois || '-'}/${p.annee || '-'}</td>
                <td>${p.propriete?.titre || '-'}</td>
                <td>${formatPrice(p.montant_paye || p.montant_total, p.devise)}</td>
                <td>
                    <span class="status-badge ${p.statut === 'paye' ? 'green' : p.statut === 'en_retard' ? 'red' : 'orange'}">
                        ${p.statut === 'paye' ? 'Payé' : p.statut === 'en_retard' ? 'En retard' : 'En attente'}
                    </span>
                </td>
            </tr>
        `).join('');
        
    } catch (error) {
        console.error('Error loading payments:', error);
    }
};

// ============================================================
// LOAD TICKET COUNT
// ============================================================
const loadTicketCount = async () => {
    if (!proprietaireId) return;
    
    try {
        const { count, error } = await supabaseClient
            .from('tickets_support')
            .select('*', { count: 'exact', head: true })
            .in('statut', ['ouvert', 'en_cours'])
            .eq('createur_id', currentUser.id);
        
        if (error) throw error;
        
        const badge = document.getElementById('ticket-count');
        if (count > 0) {
            badge.textContent = count;
            badge.style.display = 'inline-block';
        }
        
    } catch (error) {
        console.error('Error loading ticket count:', error);
    }
};

// ============================================================
// LOGOUT
// ============================================================
const initLogout = () => {
    const btnLogout = document.getElementById('btn-logout');
    if (btnLogout) {
        btnLogout.addEventListener('click', async (e) => {
            e.preventDefault();
            await logout();
        });
    }
};

// ============================================================
// INITIALIZE
// ============================================================
document.addEventListener('DOMContentLoaded', async () => {
    await initAuth();
    await loadDashboardStats();
    await loadProperties();
    await loadPayments();
    await loadTicketCount();
    initLogout();
});
