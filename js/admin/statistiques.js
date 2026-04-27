import { apiClient } from '../api-client.js';

// Initialize
document.addEventListener('DOMContentLoaded', async () => {
    checkAuth();
    await loadStats();
    setupEventListeners();
});

// Check auth
function checkAuth() {
    const user = JSON.parse(localStorage.getItem('exper_immo_user') || '{}');
    const token = localStorage.getItem('exper_immo_token');
    if (!token || !user.id) { window.location.href = '../login.html'; return; }
    if (user.role !== 'admin') { window.location.href = '../index.html'; }
}

// Load all statistics
async function loadStats() {
    try {
        // Load all data from API
        const [proprietes, locataires, proprietaires, paiements, contrats] = await Promise.all([
            apiClient.get('/properties').catch(() => []),
            apiClient.get('/locataires').catch(() => []),
            apiClient.get('/admin/proprietaires').catch(() => []),
            apiClient.get('/paiements/stats').catch(() => ({ payes: 0, en_attente: 0, en_retard: 0, revenus_mois: 0, devise: 'HTG' })),
            apiClient.get('/admin/contrats').catch(() => [])
        ]);

        // Update main stats
        setEl('stat-proprietes', proprietes.length || 0);
        setEl('stat-locataires', locataires.length || 0);
        setEl('stat-proprietaires', proprietaires.length || 0);
        setEl('stat-revenus', (paiements.revenus_mois || 0) + ' ' + (paiements.devise || 'HTG'));

        // Update payment stats
        setEl('stat-payes', paiements.payes || 0);
        setEl('stat-attente', paiements.en_attente || 0);
        setEl('stat-retard', paiements.en_retard || 0);

        // Update contracts count
        const activeContrats = contrats.filter(c => c.statut === 'actif').length;
        setEl('stat-contrats', activeContrats);

    } catch (error) {
        console.error('Error loading stats:', error);
        showToast('Erreur lors du chargement des statistiques', 'error');
        
        // Set fallback values
        setEl('stat-proprietes', '0');
        setEl('stat-locataires', '0');
        setEl('stat-proprietaires', '0');
        setEl('stat-revenus', '0 HTG');
        setEl('stat-payes', '0');
        setEl('stat-attente', '0');
        setEl('stat-retard', '0');
        setEl('stat-contrats', '0');
    }
}

// Helper to set element text
function setEl(id, value) {
    const el = document.getElementById(id);
    if (el) el.textContent = value;
}

// Update revenue chart (placeholder for Chart.js integration)
function updateRevenueChart(monthlyRevenue) {
    const container = document.querySelector('#chart-revenus');
    if (container) {
        container.innerHTML = `
            <div style="height: 200px; display: flex; align-items: center; justify-content: center; background: linear-gradient(135deg, rgba(59, 130, 246, 0.1), rgba(29, 78, 216, 0.05)); border-radius: 12px;">
                <div style="text-align: center;">
                    <i data-lucide="bar-chart-2" style="width: 48px; height: 48px; color: var(--admin-accent); margin-bottom: 16px;"></i>
                    <p style="color: var(--admin-text-muted);">Revenu mensuel: $${monthlyRevenue.toLocaleString()}</p>
                    <p style="font-size: 0.9rem; color: var(--admin-text-secondary);">Intégration Chart.js requise</p>
                </div>
            </div>
        `;
        if (typeof lucide !== 'undefined') lucide.createIcons();
    }
}

// Update property type chart
function updateTypeChart(total, disponibles, louees) {
    const container = document.querySelector('#chart-types');
    if (container) {
        const dispoPercent = total > 0 ? Math.round((disponibles / total) * 100) : 0;
        const loueePercent = total > 0 ? Math.round((louees / total) * 100) : 0;

        container.innerHTML = `
            <div style="display: flex; gap: 20px; padding: 20px;">
                <div style="flex: 1; text-align: center;">
                    <div style="width: 120px; height: 120px; border-radius: 50%; background: conic-gradient(#10b981 ${loueePercent}%, #f59e0b ${dispoPercent}%, #e5e7eb 0%); margin: 0 auto 16px;"></div>
                    <p style="font-weight: 600;">${loueePercent}% Louées</p>
                </div>
                <div style="flex: 1; display: flex; flex-direction: column; justify-content: center; gap: 12px;">
                    <div style="display: flex; align-items: center; gap: 12px;">
                        <div style="width: 16px; height: 16px; border-radius: 4px; background: #10b981;"></div>
                        <span>Louées: ${louees}</span>
                    </div>
                    <div style="display: flex; align-items: center; gap: 12px;">
                        <div style="width: 16px; height: 16px; border-radius: 4px; background: #f59e0b;"></div>
                        <span>Disponibles: ${disponibles}</span>
                    </div>
                    <div style="display: flex; align-items: center; gap: 12px;">
                        <div style="width: 16px; height: 16px; border-radius: 4px; background: #e5e7eb;"></div>
                        <span>Total: ${total}</span>
                    </div>
                </div>
            </div>
        `;
    }
}

// Update geographic distribution
function updateGeographicChart() {
    const container = document.querySelector('#chart-geo');
    if (container) {
        container.innerHTML = `
            <div style="height: 200px; display: flex; align-items: center; justify-content: center; background: linear-gradient(135deg, rgba(16, 185, 129, 0.1), rgba(5, 150, 105, 0.05)); border-radius: 12px;">
                <div style="text-align: center;">
                    <i data-lucide="map-pin" style="width: 48px; height: 48px; color: var(--admin-success); margin-bottom: 16px;"></i>
                    <p style="color: var(--admin-text-muted);">Carte interactive requiert Google Maps API</p>
                </div>
            </div>
        `;
        if (typeof lucide !== 'undefined') lucide.createIcons();
    }
}

// Update conversion chart
function updateConversionChart(visiteurs, locataires) {
    const container = document.querySelector('#chart-conversion');
    if (container) {
        const visiteursEstime = visiteurs * 10; // Estimation
        const tauxConversion = visiteursEstime > 0 
            ? ((locataires / visiteursEstime) * 100).toFixed(1) 
            : 0;

        container.innerHTML = `
            <div style="padding: 20px;">
                <div style="margin-bottom: 20px;">
                    <div style="display: flex; justify-content: space-between; margin-bottom: 8px;">
                        <span>Visiteurs estimés</span>
                        <strong>${visiteursEstime}</strong>
                    </div>
                    <div style="height: 12px; background: #e5e7eb; border-radius: 6px; overflow: hidden;">
                        <div style="width: 100%; height: 100%; background: linear-gradient(90deg, #3b82f6, #1d4ed8);"></div>
                    </div>
                </div>
                <div>
                    <div style="display: flex; justify-content: space-between; margin-bottom: 8px;">
                        <span>Locataires</span>
                        <strong>${locataires}</strong>
                    </div>
                    <div style="height: 12px; background: #e5e7eb; border-radius: 6px; overflow: hidden;">
                        <div style="width: ${tauxConversion}%; height: 100%; background: linear-gradient(90deg, #10b981, #059669);"></div>
                    </div>
                </div>
                <div style="margin-top: 20px; text-align: center; padding: 16px; background: linear-gradient(135deg, rgba(16, 185, 129, 0.1), rgba(5, 150, 105, 0.05)); border-radius: 12px;">
                    <p style="font-size: 2rem; font-weight: 700; color: #10b981; margin-bottom: 4px;">${tauxConversion}%</p>
                    <p style="color: var(--admin-text-muted);">Taux de conversion</p>
                </div>
            </div>
        `;
    }
}

// Setup event listeners
function setupEventListeners() {
    const logoutBtn = document.getElementById('btn-logout');
    if (logoutBtn) {
        logoutBtn.addEventListener('click', async () => {
            localStorage.removeItem('exper_immo_token'); localStorage.removeItem('exper_immo_user');
            window.location.href = '../login.html';
        });
    }
}

// Show toast
function showToast(message, type = 'info') {
    const toast = document.createElement('div');
    toast.className = `toast toast-${type}`;
    toast.innerHTML = `<i data-lucide="${type === 'success' ? 'check-circle' : type === 'error' ? 'alert-circle' : 'info'}"></i><span>${message}</span>`;
    document.body.appendChild(toast);
    if (typeof lucide !== 'undefined') lucide.createIcons();
    setTimeout(() => toast.remove(), 5000);
}
