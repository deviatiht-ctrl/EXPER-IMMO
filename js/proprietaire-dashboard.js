// proprietaire-dashboard.js - Proprietaire Portal Logic
import { apiClient } from './api-client.js';
import { showToast, formatPrice } from './utils.js';

// ============================================================
// AUTH CHECK
// ============================================================
let currentUser = null;
let proprietaireId = null;

const initAuth = async () => {
    const token = localStorage.getItem('exper_immo_token');
    const user = JSON.parse(localStorage.getItem('exper_immo_user') || '{}');
    
    if (!token || !user.id) {
        window.location.href = '../login.html';
        return;
    }
    
    if (user.role !== 'proprietaire' && user.role !== 'admin') {
        window.location.href = '../index.html';
        return;
    }
    
    currentUser = user;
    
    // Try to get proprietaire info from API
    try {
        const proprietaires = await apiClient.get('/admin/proprietaires');
        const proprietaire = proprietaires?.find(p => p.user_id === user.id) || proprietaires?.[0];
        proprietaireId = proprietaire?.id_proprietaire || proprietaire?.id;
    } catch (e) {
        console.warn('Could not load proprietaire details:', e);
    }
    
    // Update UI with user info
    const userName = user.prenom || user.nom || user.email || 'Propriétaire';
    document.getElementById('user-name').textContent = userName;
    document.getElementById('user-avatar').textContent = userName.charAt(0).toUpperCase();
    document.getElementById('last-login').textContent = new Date().toLocaleString('fr-FR');
    document.getElementById('welcome-title').textContent = `Heureux de vous revoir, ${userName}`;
};

// ============================================================
// LOAD DASHBOARD STATS CDC 5.2.1
// ============================================================
const loadDashboardStats = async () => {
    if (!proprietaireId) return;
    
    try {
        // Fetch all properties from API
        const proprietes = await apiClient.get('/properties').catch(() => []);
        
        // Total biens
        const total = proprietes.length;
        // En Gestion (filter locally since backend may not support filtering yet)
        const gestion = proprietes.filter(p => p.statut_bien === 'gestion' || p.type_mandat === 'gestion').length;
        // En Construction
        const construction = proprietes.filter(p => p.statut_bien === 'construction' || p.statut === 'construction').length;
        
        // Ops récentes (operations endpoint may not exist yet, use 0 for now)
        const ops = 0;

        document.getElementById('stat-total-biens').textContent = total || 0;
        document.getElementById('stat-en-gestion').textContent = gestion || 0;
        document.getElementById('stat-en-construction').textContent = construction || 0;
        document.getElementById('stat-ops-recentes').textContent = ops;
        
    } catch (error) {
        console.error('Error loading stats:', error);
        // Set fallback values
        document.getElementById('stat-total-biens').textContent = '0';
        document.getElementById('stat-en-gestion').textContent = '0';
        document.getElementById('stat-en-construction').textContent = '0';
        document.getElementById('stat-ops-recentes').textContent = '0';
    }
};

// ============================================================
// LOAD PROPERTIES
// ============================================================
const loadProperties = async () => {
    if (!proprietaireId) return;
    
    try {
        const properties = await apiClient.get('/properties').catch(() => []);
        
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
        
        // Filter proprietaire's properties and limit to 3
        const myProperties = properties.slice(0, 3);
        
        grid.innerHTML = myProperties.map(prop => `
            <div class="property-card-mini">
                <img src="${prop.images?.[0] || prop.image || 'https://images.unsplash.com/photo-1564013799919-ab600027ffc6?auto=format&fit=crop&q=80&w=400'}" 
                     alt="${prop.title || prop.titre || 'Propriété'}">
                <div class="property-card-mini-body">
                    <h4>${prop.title || prop.titre || 'Sans titre'}</h4>
                    <div class="location">
                        <i data-lucide="map-pin"></i>
                        ${prop.zone || prop.ville || prop.address || 'Adresse non spécifiée'}
                    </div>
                    <div class="property-card-mini-stats">
                        <div class="stat">
                            <div class="stat-value">${formatPrice(prop.prix_location || prop.prix_vente || prop.prix || 0, prop.devise || 'HTG')}</div>
                            <div class="stat-label">${prop.type_transaction === 'location' ? '/mois' : ''}</div>
                        </div>
                        <div class="stat">
                            <div class="stat-value">${prop.statut === 'loue' || prop.status === 'rented' ? 'Loué' : 'Disponible'}</div>
                            <div class="stat-label">Statut</div>
                        </div>
                    </div>
                </div>
            </div>
        `).join('');
        
        if (typeof lucide !== 'undefined') lucide.createIcons();
        
    } catch (error) {
        console.error('Error loading properties:', error);
        document.getElementById('properties-grid').innerHTML = `
            <div class="empty-state">
                <i data-lucide="alert-circle"></i>
                <h3>Erreur de chargement</h3>
                <p>Impossible de charger vos propriétés.</p>
            </div>
        `;
    }
};

// ============================================================
// LOAD PAYMENTS
// ============================================================
const loadPayments = async () => {
    if (!proprietaireId) return;
    
    try {
        // Payments endpoint may not exist yet, show placeholder
        const tbody = document.getElementById('finances-tbody');
        
        // For now, show empty state - paiements endpoint needs to be implemented
        tbody.innerHTML = `
            <tr>
                <td colspan="4" class="text-center text-muted">Aucun paiement enregistré</td>
            </tr>
        `;
        
        /*
        // When API endpoint is ready:
        const payments = await apiClient.get('/paiements').catch(() => []);
        
        if (!payments || payments.length === 0) {
            tbody.innerHTML = `
                <tr>
                    <td colspan="4" class="text-center text-muted">Aucun paiement enregistré</td>
                </tr>
            `;
            return;
        }
        
        tbody.innerHTML = payments.slice(0, 5).map(p => `
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
        */
        
    } catch (error) {
        console.error('Error loading payments:', error);
        const tbody = document.getElementById('finances-tbody');
        if (tbody) {
            tbody.innerHTML = `
                <tr>
                    <td colspan="4" class="text-center text-muted">Erreur de chargement</td>
                </tr>
            `;
        }
    }
};

// ============================================================
// LOAD TICKET COUNT
// ============================================================
const loadTicketCount = async () => {
    if (!proprietaireId) return;
    
    // Tickets endpoint may not exist yet, skip for now
    // When ready: const tickets = await apiClient.get('/tickets').catch(() => []);
    
    const badge = document.getElementById('ticket-count');
    if (badge) {
        badge.style.display = 'none';
    }
};

// ============================================================
// LOGOUT
// ============================================================
const initLogout = () => {
    const btnLogout = document.getElementById('btn-logout');
    if (btnLogout) {
        btnLogout.addEventListener('click', (e) => {
            e.preventDefault();
            localStorage.removeItem('exper_immo_token');
            localStorage.removeItem('exper_immo_user');
            window.location.href = '../login.html';
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
