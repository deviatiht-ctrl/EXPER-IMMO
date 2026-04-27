// proprietaire-properties.js - Proprietaire Properties Page
import { apiClient } from './api-client.js';
import { showToast, formatPrice } from './utils.js';

let currentUser = null;
let proprietaireId = null;
let allProperties = [];

const initAuth = () => {
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
    proprietaireId = user.proprietaire_id || user.id;
    
    const userName = user.prenom || user.nom || user.email || 'Propriétaire';
    document.getElementById('user-name').textContent = userName;
    document.getElementById('user-avatar').textContent = userName.charAt(0).toUpperCase();
};

const loadProperties = async () => {
    if (!proprietaireId) return;
    
    try {
        const properties = await apiClient.get('/properties').catch(() => []);
        
        allProperties = properties || [];
        renderProperties(allProperties);
        document.getElementById('prop-count').textContent = allProperties.length;
        
    } catch (error) {
        console.error('Error loading properties:', error);
        showToast('Erreur lors du chargement des propriétés', 'error');
    }
};

const renderProperties = (properties) => {
    const grid = document.getElementById('properties-grid');
    const emptyState = document.getElementById('empty-state');
    
    if (!properties || properties.length === 0) {
        grid.innerHTML = '';
        emptyState.style.display = 'block';
        return;
    }
    
    emptyState.style.display = 'none';
    
    grid.innerHTML = properties.map(prop => `
        <div class="property-card-mini">
            <img src="${prop.images?.[0] || 'https://images.unsplash.com/photo-1564013799919-ab600027ffc6?auto=format&fit=crop&q=80&w=400'}" 
                 alt="${prop.titre}">
            <div class="property-card-mini-body">
                <div class="flex justify-between items-start mb-2">
                    <h4>${prop.titre}</h4>
                    <span class="status-badge ${getStatusClass(prop.statut)}">
                        ${getStatusLabel(prop.statut)}
                    </span>
                </div>
                <div class="location">
                    <i data-lucide="map-pin"></i>
                    ${prop.zones?.nom || prop.ville}
                </div>
                <div class="property-card-mini-stats">
                    <div class="stat">
                        <div class="stat-value">${formatPrice(prop.prix, prop.devise)}</div>
                        <div class="stat-label">${prop.type_transaction === 'location' ? '/mois' : ''}</div>
                    </div>
                    <div class="stat">
                        <div class="stat-value">${prop.nb_chambres || 0}</div>
                        <div class="stat-label">Chambres</div>
                    </div>
                    <div class="stat">
                        <div class="stat-value">${prop.superficie_m2 || 0}m²</div>
                        <div class="stat-label">Surface</div>
                    </div>
                </div>
                <div class="mt-3 flex gap-2">
                    <a href="detail-propriete.html?id=${prop.id_propriete}" class="btn-outline btn-sm flex-1">
                        <i data-lucide="eye"></i> Voir
                    </a>
                    <a href="modifier-propriete.html?id=${prop.id_propriete}" class="btn-primary btn-sm flex-1">
                        <i data-lucide="edit"></i> Modifier
                    </a>
                </div>
            </div>
        </div>
    `).join('');
    
    lucide.createIcons();
};

const getStatusClass = (statut) => {
    switch (statut) {
        case 'disponible': return 'green';
        case 'loue': return 'blue';
        case 'vendu': return 'gray';
        case 'sous_compromis': return 'orange';
        default: return 'gray';
    }
};

const getStatusLabel = (statut) => {
    switch (statut) {
        case 'disponible': return 'Disponible';
        case 'loue': return 'Loué';
        case 'vendu': return 'Vendu';
        case 'sous_compromis': return 'Sous compromis';
        default: return statut;
    }
};

const filterProperties = () => {
    const statut = document.getElementById('filter-statut').value;
    const type = document.getElementById('filter-type').value;
    const search = document.getElementById('search').value.toLowerCase();
    
    let filtered = allProperties;
    
    if (statut) {
        filtered = filtered.filter(p => p.statut === statut);
    }
    
    if (type) {
        filtered = filtered.filter(p => p.type_propriete === type);
    }
    
    if (search) {
        filtered = filtered.filter(p => 
            p.titre?.toLowerCase().includes(search) ||
            p.adresse?.toLowerCase().includes(search) ||
            p.reference?.toLowerCase().includes(search)
        );
    }
    
    renderProperties(filtered);
};

const initFilters = () => {
    document.getElementById('filter-statut').addEventListener('change', filterProperties);
    document.getElementById('filter-type').addEventListener('change', filterProperties);
    document.getElementById('search').addEventListener('input', filterProperties);
};

const initLogout = () => {
    document.getElementById('btn-logout')?.addEventListener('click', (e) => {
        e.preventDefault();
        localStorage.removeItem('exper_immo_token');
        localStorage.removeItem('exper_immo_user');
        window.location.href = '../login.html';
    });
};

document.addEventListener('DOMContentLoaded', async () => {
    await initAuth();
    await loadProperties();
    initFilters();
    initLogout();
});
