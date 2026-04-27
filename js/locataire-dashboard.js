import { apiClient } from './api-client.js';

let currentUser = null;
let locataireId = null;

const initAuth = () => {
    const token = localStorage.getItem('exper_immo_token');
    const user = JSON.parse(localStorage.getItem('exper_immo_user') || '{}');
    
    if (!token || !user.id) {
        window.location.href = '../login.html';
        return;
    }
    
    if (user.role !== 'locataire' && user.role !== 'admin') {
        window.location.href = '../index.html';
        return;
    }
    
    currentUser = user;
    locataireId = user.locataire_id || user.id;
    
    const userName = user.prenom || user.nom || user.email || 'Locataire';
    document.getElementById('user-name').textContent = userName;
    document.getElementById('last-login').textContent = new Date().toLocaleString('fr-FR');
    document.getElementById('welcome-title').textContent = `Bonjour, ${userName}`;
};

const loadDashboardData = async () => {
    if (!locataireId) return;
    
    try {
        // Try to load contracts from API
        const contrats = await apiClient.get('/admin/contrats').catch(() => []);
        const contrat = contrats.find(c => c.locataire_id === locataireId && c.statut === 'actif');
        
        if (contrat) {
            document.getElementById('stat-bien-occupe').textContent = contrat.propriete?.titre || 'Oui';
            document.getElementById('stat-contrat-statut').textContent = 'Actif';
        } else {
            document.getElementById('stat-bien-occupe').textContent = '-';
            document.getElementById('stat-contrat-statut').textContent = 'Aucun';
        }
        
        // Factures endpoint not ready yet - show placeholder
        const tbody = document.getElementById('factures-tbody');
        tbody.innerHTML = '<tr><td colspan="4" class="text-center">Aucune facture récente.</td></tr>';
        
    } catch (error) {
        console.error('Error loading dashboard data:', error);
    }
};

document.addEventListener('DOMContentLoaded', async () => {
    await initAuth();
    await loadDashboardData();
    if(typeof lucide !== 'undefined') lucide.createIcons();
});
