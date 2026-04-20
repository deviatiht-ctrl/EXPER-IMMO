// proprietaire-edit-property.js - Edit Property Page
import CONFIG from './config.js';
import { showToast, formatPrice } from './utils.js';
import { requireAuth, logout, supabaseClient } from './auth.js';

let currentUser = null;
let proprietaireId = null;
let propertyId = null;

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

const getPropertyIdFromUrl = () => {
    const params = new URLSearchParams(window.location.search);
    return params.get('id');
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
        const { data: property, error } = await supabaseClient
            .from('proprietes')
            .select('*')
            .eq('id_propriete', propertyId)
            .eq('proprietaire_id', proprietaireId)
            .single();
        
        if (error || !property) {
            showError('Propriété non trouvée');
            return;
        }
        
        populateForm(property);
        
    } catch (err) {
        console.error('Error:', err);
        showError('Erreur lors du chargement');
    }
};

const populateForm = (property) => {
    // Hide loading, show form
    document.getElementById('loading-state').style.display = 'none';
    document.getElementById('edit-form').style.display = 'block';
    
    // Update page title
    document.title = `Modifier: ${property.titre} | EXPERIMMO`;
    
    // Update view button
    document.getElementById('btn-view').href = `detail-propriete.html?id=${property.id_propriete}`;
    
    // Populate form fields
    document.getElementById('property-id').value = property.id_propriete;
    document.getElementById('titre').value = property.titre || '';
    document.getElementById('reference').value = property.reference || '';
    document.getElementById('type_propriete').value = property.type_propriete || '';
    document.getElementById('type_transaction').value = property.type_transaction || '';
    document.getElementById('statut').value = property.statut || 'disponible';
    document.getElementById('statut_bien').value = property.statut_bien || '';
    document.getElementById('adresse').value = property.adresse || '';
    document.getElementById('ville').value = property.ville || '';
    document.getElementById('superficie_m2').value = property.superficie_m2 || '';
    document.getElementById('nb_chambres').value = property.nb_chambres || '';
    document.getElementById('nb_salles_bain').value = property.nb_salles_bain || '';
    document.getElementById('nb_etages').value = property.nb_etages || '';
    document.getElementById('annee_construction').value = property.annee_construction || '';
    document.getElementById('prix_vente').value = property.prix_vente || '';
    document.getElementById('prix_location').value = property.prix_location || '';
    document.getElementById('devise').value = property.devise || 'HTG';
    document.getElementById('description').value = property.description || '';
    
    lucide.createIcons();
};

const handleSubmit = async (e) => {
    e.preventDefault();
    
    if (!propertyId) {
        showToast('Erreur: ID propriété manquant', 'error');
        return;
    }
    
    const btnSubmit = document.getElementById('btn-submit');
    btnSubmit.disabled = true;
    btnSubmit.innerHTML = '<i data-lucide="loader-2"></i> Enregistrement...';
    lucide.createIcons();
    
    try {
        const formData = {
            titre: document.getElementById('titre').value.trim(),
            type_propriete: document.getElementById('type_propriete').value,
            type_transaction: document.getElementById('type_transaction').value,
            statut: document.getElementById('statut').value,
            statut_bien: document.getElementById('statut_bien').value || null,
            adresse: document.getElementById('adresse').value.trim(),
            ville: document.getElementById('ville').value,
            superficie_m2: parseFloat(document.getElementById('superficie_m2').value) || null,
            nb_chambres: parseInt(document.getElementById('nb_chambres').value) || null,
            nb_salles_bain: parseInt(document.getElementById('nb_salles_bain').value) || null,
            nb_etages: parseInt(document.getElementById('nb_etages').value) || null,
            annee_construction: parseInt(document.getElementById('annee_construction').value) || null,
            prix_vente: parseFloat(document.getElementById('prix_vente').value) || null,
            prix_location: parseFloat(document.getElementById('prix_location').value) || null,
            prix: parseFloat(document.getElementById('prix_vente').value) || parseFloat(document.getElementById('prix_location').value) || 0,
            devise: document.getElementById('devise').value,
            description: document.getElementById('description').value.trim(),
            updated_at: new Date().toISOString()
        };
        
        const { error } = await supabaseClient
            .from('proprietes')
            .update(formData)
            .eq('id_propriete', propertyId)
            .eq('proprietaire_id', proprietaireId);
        
        if (error) {
            console.error('Supabase error:', error);
            throw new Error(error.message || 'Erreur lors de la mise à jour');
        }
        
        showToast('Propriété mise à jour avec succès!', 'success');
        
        // Redirect after 1.5 seconds
        setTimeout(() => {
            window.location.href = `detail-propriete.html?id=${propertyId}`;
        }, 1500);
        
    } catch (err) {
        console.error('Error:', err);
        showToast(err.message || 'Erreur lors de la mise à jour', 'error');
        
        btnSubmit.disabled = false;
        btnSubmit.innerHTML = '<i data-lucide="save"></i> Enregistrer les modifications';
        lucide.createIcons();
    }
};

const handleDelete = async () => {
    if (!confirm('Êtes-vous sûr de vouloir supprimer cette propriété ? Cette action est irréversible.')) {
        return;
    }
    
    try {
        const { error } = await supabaseClient
            .from('proprietes')
            .delete()
            .eq('id_propriete', propertyId)
            .eq('proprietaire_id', proprietaireId);
        
        if (error) {
            throw new Error(error.message);
        }
        
        showToast('Propriété supprimée avec succès', 'success');
        
        setTimeout(() => {
            window.location.href = 'mes-proprietes.html';
        }, 1500);
        
    } catch (err) {
        console.error('Error:', err);
        showToast(err.message || 'Erreur lors de la suppression', 'error');
    }
};

const showError = (message) => {
    document.getElementById('loading-state').style.display = 'none';
    document.getElementById('edit-form').style.display = 'none';
    document.getElementById('error-state').style.display = 'block';
    lucide.createIcons();
};

const initForm = () => {
    const form = document.getElementById('form-modifier-propriete');
    if (form) {
        form.addEventListener('submit', handleSubmit);
    }
    
    const btnDelete = document.getElementById('btn-delete');
    if (btnDelete) {
        btnDelete.addEventListener('click', handleDelete);
    }
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
    initForm();
    initLogout();
});
