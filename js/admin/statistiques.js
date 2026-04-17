import { supabase } from '../supabase-client.js';

// Initialize
document.addEventListener('DOMContentLoaded', async () => {
    await checkAuth();
    await loadStats();
    setupEventListeners();
});

// Check auth
async function checkAuth() {
    const { data: { user } } = await supabase.auth.getUser();
    if (!user) {
        window.location.href = '../login.html';
        return;
    }
    
    const { data: profile } = await supabase
        .from('profiles')
        .select('role')
        .eq('id', user.id)
        .single();
    
    if (profile?.role !== 'admin') {
        window.location.href = '../index.html';
        return;
    }
}

// Load all statistics
async function loadStats() {
    try {
        // Get all stats in parallel
        const [
            totalProprietaires,
            totalLocataires,
            totalProprietes,
            proprietesDisponibles,
            proprietesLouees,
            contratsActifs,
            paiementsEnAttente,
            ticketsOuverts,
            revenusMensuels,
            revenusTotaux
        ] = await Promise.all([
            getCount('proprietaires'),
            getCount('locataires'),
            getCount('proprietes'),
            getCount('proprietes', 'statut', 'disponible'),
            getCount('proprietes', 'statut', 'loue'),
            getCount('contrats', 'statut', 'actif'),
            getCount('paiements', 'statut', 'en_attente'),
            getCount('tickets_support', 'statut', 'ouvert'),
            getRevenusMensuels(),
            getRevenusTotaux()
        ]);

        // Calculate occupancy rate
        const tauxOccupation = totalProprietes > 0 
            ? Math.round((proprietesLouees / totalProprietes) * 100) 
            : 0;

        // Calculate growth (simplified - would need historical data)
        const croissance = '+23%'; // Placeholder

        // Update stat cards
        updateStatCard(0, `${croissance}`, 'Croissance annuelle');
        updateStatCard(1, `$${revenusTotaux.toLocaleString()}K`, 'Revenus totaux');
        updateStatCard(2, `${tauxOccupation}%`, 'Taux d\'occupation');
        updateStatCard(3, '4.8', 'Note moyenne');

        // Update detailed charts
        updateRevenueChart(revenusMensuels);
        updateTypeChart(totalProprietes, proprietesDisponibles, proprietesLouees);
        updateGeographicChart();
        updateConversionChart(totalLocataires, contratsActifs);

    } catch (error) {
        console.error('Error loading stats:', error);
        showToast('Erreur lors du chargement des statistiques', 'error');
    }
}

// Get count with optional filter
async function getCount(table, column = null, value = null) {
    let query = supabase.from(table).select('*', { count: 'exact', head: true });
    
    if (column && value) {
        query = query.eq(column, value);
    }

    const { count } = await query;
    return count || 0;
}

// Get monthly revenue
async function getRevenusMensuels() {
    const { data } = await supabase
        .from('paiements')
        .select('montant_total')
        .eq('statut', 'paye')
        .gte('date_paiement', new Date(new Date().setDate(1)).toISOString());

    return data?.reduce((sum, p) => sum + (p.montant_total || 0), 0) || 0;
}

// Get total revenue
async function getRevenusTotaux() {
    const { data } = await supabase
        .from('paiements')
        .select('montant_total')
        .eq('statut', 'paye');

    return (data?.reduce((sum, p) => sum + (p.montant_total || 0), 0) || 0) / 1000;
}

// Update stat card display
function updateStatCard(index, value, label) {
    const statCards = document.querySelectorAll('.stats-grid .stat-card h3');
    const labels = document.querySelectorAll('.stats-grid .stat-card p');
    
    if (statCards[index] && labels[index]) {
        statCards[index].textContent = value;
        labels[index].textContent = label;
    }
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
            await supabase.auth.signOut();
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
