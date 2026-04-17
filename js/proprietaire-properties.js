// proprietaire-properties.js - Proprietaire Properties Page
import CONFIG from './config.js';
import { showToast, formatPrice } from './utils.js';
import { requireAuth, logout, supabaseClient } from './auth.js';

let currentUser = null;
let proprietaireId = null;
let allProperties = [];

const initAuth = async () => {
    currentUser = await requireAuth(['proprietaire']);
    if (!currentUser) return;
    
    const { data: proprietaire } = await supabaseClient
        .from('proprietaires')
        .select('id_proprietaire')
        .eq('user_id', currentUser.id)
        .single();
    
    proprietaireId = proprietaire?.id_proprietaire;
    
    document.getElementById('user-name').textContent = currentUser.profile?.full_name || 'Propriétaire';
    document.getElementById('user-avatar').textContent = 
        (currentUser.profile?.full_name || 'P').charAt(0).toUpperCase();
};

const loadProperties = async () => {
    if (!proprietaireId) return;
    
    try {
        const { data: properties, error } = await supabaseClient
            .from('proprietes')
            .select('*, zones(nom)')
            .eq('proprietaire_id', proprietaireId)
            .eq('est_actif', true)
            .order('created_at', { ascending: false });
        
        if (error) throw error;
        
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
    document.getElementById('btn-logout').addEventListener('click', async (e) => {
        e.preventDefault();
        await logout();
    });
};

document.addEventListener('DOMContentLoaded', async () => {
    await initAuth();
    await loadProperties();
    initFilters();
    initLogout();
});
