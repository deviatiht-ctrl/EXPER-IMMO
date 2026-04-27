// proprietaire-detail-property.js - Property Detail Page
import { apiClient } from './api-client.js';
import { showToast, formatPrice } from './utils.js';

let currentUser = null;
let proprietaireId = null;
let propertyId = null;

const initAuth = () => {
    const user = JSON.parse(localStorage.getItem('exper_immo_user') || '{}');
    const token = localStorage.getItem('exper_immo_token');
    if (!token || !user.id) { window.location.href = '../login.html'; return false; }
    if (user.role !== 'proprietaire' && user.role !== 'admin') { window.location.href = '../index.html'; return false; }
    
    currentUser = user;
    proprietaireId = user.proprietaire_id || user.id;
    
    const name = (`${user.prenom || ''} ${user.nom || ''}`).trim() || user.email || 'Propriétaire';
    const el = document.getElementById('user-name');
    if (el) el.textContent = name;
    const av = document.getElementById('user-avatar');
    if (av) av.textContent = name.charAt(0).toUpperCase();
    return true;
};

const getPropertyIdFromUrl = () => {
    const params = new URLSearchParams(window.location.search);
    return params.get('id');
};

const getStatusLabel = (statut) => {
    const labels = {
        'disponible': 'Disponible',
        'loue': 'Loué',
        'vendu': 'Vendu',
        'sous_compromis': 'Sous compromis',
        'en_construction': 'En construction',
        'gestion': 'En gestion'
    };
    return labels[statut] || statut;
};

const getStatusClass = (statut) => {
    const classes = {
        'disponible': 'green',
        'loue': 'blue',
        'vendu': 'gray',
        'sous_compromis': 'orange',
        'en_construction': 'orange',
        'gestion': 'purple'
    };
    return classes[statut] || 'gray';
};

const getTypeLabel = (type) => {
    const labels = {
        'maison': 'Maison',
        'appartement': 'Appartement',
        'villa': 'Villa',
        'terrain': 'Terrain',
        'local_commercial': 'Local Commercial',
        'entrepot': 'Entrepôt'
    };
    return labels[type] || type;
};

const getTransactionLabel = (type) => {
    const labels = {
        'location': 'Location',
        'vente': 'Vente',
        'lesion_bail': 'Léger-bail',
        'co_propriete': 'Co-propriété'
    };
    return labels[type] || type;
};

const loadProperty = async () => {
    propertyId = getPropertyIdFromUrl();
    
    if (!propertyId) {
        showError('Aucun ID de propriété spécifié');
        return;
    }
    
    if (!proprietaireId) {
        showError('Impossible d\'identifier le propriétaire');
        return;
    }
    
    try {
        const props = await apiClient.get('/properties').catch(() => []);
        const property = props.find(p => String(p.id || p.id_propriete) === String(propertyId));
        
        if (!property) {
            showError('Propriété non trouvée');
            return;
        }
        
        displayProperty(property);
        
    } catch (err) {
        console.error('Error:', err);
        showError('Erreur lors du chargement');
    }
};

const displayProperty = (property) => {
    // Hide loading, show content
    document.getElementById('loading-state').style.display = 'none';
    document.getElementById('property-details').style.display = 'block';
    
    // Update page title
    document.title = `${property.titre} | EXPERIMMO`;
    document.getElementById('page-title').innerHTML = `<i data-lucide="building-2"></i> ${property.titre}`;
    
    // Update edit button link
    const btnEdit = document.getElementById('btn-edit');
    btnEdit.href = `modifier-propriete.html?id=${property.id_propriete}`;
    
    // Image
    const img = document.getElementById('prop-image');
    img.src = property.images?.[0] || 'https://images.unsplash.com/photo-1564013799919-ab600027ffc6?auto=format&fit=crop&q=80&w=800';
    img.alt = property.titre;
    
    // Status badge
    const statusBadge = document.getElementById('prop-status');
    statusBadge.textContent = getStatusLabel(property.statut);
    statusBadge.className = `status-badge ${getStatusClass(property.statut)}`;
    
    // Reference
    document.getElementById('prop-ref').textContent = `Ref: ${property.reference || 'N/A'}`;
    
    // Title
    // Already set in page-title
    
    // Address
    document.getElementById('prop-address').textContent = `${property.adresse}, ${property.ville}`;
    
    // Price
    const price = property.prix_vente || property.prix_location || property.prix || 0;
    const isLocation = property.type_transaction === 'location';
    document.getElementById('prop-price').textContent = formatPrice(price, property.devise);
    document.getElementById('prop-period').textContent = isLocation ? '/mois' : '';
    
    // Features
    document.getElementById('feat-superficie').textContent = property.superficie_m2 || '-';
    document.getElementById('feat-chambres').textContent = property.nb_chambres || '-';
    document.getElementById('feat-sdb').textContent = property.nb_salles_bain || '-';
    document.getElementById('feat-etages').textContent = property.nb_etages || '-';
    document.getElementById('feat-type').textContent = getTypeLabel(property.type_propriete);
    document.getElementById('feat-transaction').textContent = getTransactionLabel(property.type_transaction);
    
    // Year
    if (property.annee_construction) {
        document.getElementById('feat-annee').style.display = 'block';
        document.querySelector('#feat-annee span').textContent = property.annee_construction;
    }
    
    // Description
    document.getElementById('prop-description').textContent = property.description || 'Aucune description disponible.';
    
    // Info
    document.getElementById('info-ref').textContent = property.reference || 'N/A';
    document.getElementById('info-date').textContent = new Date(property.created_at).toLocaleDateString('fr-FR');
    document.getElementById('info-statut-bien').textContent = property.statut_bien ? getStatusLabel(property.statut_bien) : 'Non spécifié';
    document.getElementById('info-update').textContent = new Date(property.updated_at).toLocaleDateString('fr-FR');
    
    // Refresh icons
    lucide.createIcons();
};

const showError = (message) => {
    document.getElementById('loading-state').style.display = 'none';
    document.getElementById('property-details').style.display = 'none';
    document.getElementById('error-state').style.display = 'block';
    lucide.createIcons();
};

const initLogout = () => {
    const btnLogout = document.getElementById('btn-logout');
    if (btnLogout) {
        btnLogout.addEventListener('click', async (e) => {
            e.preventDefault();
            await logout();
        });
    }
};

document.addEventListener('DOMContentLoaded', async () => {
    await initAuth();
    await loadProperty();
    initLogout();
});
