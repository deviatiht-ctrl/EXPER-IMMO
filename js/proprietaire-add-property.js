// proprietaire-add-property.js - Add Property Page
import CONFIG from './config.js';
import { showToast, formatPrice } from './utils.js';
import { requireAuth, logout, supabaseClient } from './auth.js';

let currentUser = null;
let proprietaireId = null;
let uploadedPhotos = []; // Store selected files

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

const generateReference = () => {
    const date = new Date();
    const year = date.getFullYear().toString().slice(-2);
    const month = String(date.getMonth() + 1).padStart(2, '0');
    const day = String(date.getDate()).padStart(2, '0');
    const random = Math.floor(Math.random() * 1000).toString().padStart(3, '0');
    return `PROP-${year}${month}${day}-${random}`;
};

const handleSubmit = async (e) => {
    e.preventDefault();
    
    if (!proprietaireId) {
        showToast('Erreur: Impossible d\'identifier le propriétaire', 'error');
        return;
    }
    
    const btnSubmit = document.getElementById('btn-submit');
    btnSubmit.disabled = true;
    btnSubmit.innerHTML = '<i data-lucide="loader-2"></i> Enregistrement...';
    lucide.createIcons();
    
    try {
        // Upload photos first
        showToast('Upload des photos en cours...', 'info');
        const photoUrls = await uploadPhotosToStorage('temp'); // Will be moved after property creation
        
        // Collect form data
        const formData = {
            titre: document.getElementById('titre').value.trim(),
            reference: document.getElementById('reference').value.trim() || generateReference(),
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
            proprietaire_id: proprietaireId,
            est_actif: true,
            images: photoUrls, // Add photo URLs
            created_at: new Date().toISOString(),
            updated_at: new Date().toISOString()
        };
        
        // Insert into Supabase
        const { data, error } = await supabaseClient
            .from('proprietes')
            .insert([formData])
            .select()
            .single();
        
        if (error) {
            console.error('Supabase error:', error);
            throw new Error(error.message || 'Erreur lors de l\'enregistrement');
        }
        
        showToast('Propriété ajoutée avec succès!', 'success');
        
        // Redirect after 1.5 seconds
        setTimeout(() => {
            window.location.href = 'mes-proprietes.html';
        }, 1500);
        
    } catch (err) {
        console.error('Error:', err);
        showToast(err.message || 'Erreur lors de l\'enregistrement', 'error');
        
        btnSubmit.disabled = false;
        btnSubmit.innerHTML = '<i data-lucide="save"></i> Enregistrer la propriété';
        lucide.createIcons();
    }
};

const initForm = () => {
    const form = document.getElementById('form-ajouter-propriete');
    if (form) {
        form.addEventListener('submit', handleSubmit);
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

// ============================================================
// PHOTO UPLOAD HANDLING
// ============================================================
const initPhotoUpload = () => {
    const dropzone = document.getElementById('photo-dropzone');
    const fileInput = document.getElementById('photos-input');
    
    if (!dropzone || !fileInput) return;
    
    // Click to upload
    dropzone.addEventListener('click', () => fileInput.click());
    
    // File selection
    fileInput.addEventListener('change', handleFileSelect);
    
    // Drag and drop
    dropzone.addEventListener('dragover', (e) => {
        e.preventDefault();
        dropzone.classList.add('dragover');
    });
    
    dropzone.addEventListener('dragleave', () => {
        dropzone.classList.remove('dragover');
    });
    
    dropzone.addEventListener('drop', (e) => {
        e.preventDefault();
        dropzone.classList.remove('dragover');
        const files = Array.from(e.dataTransfer.files).filter(f => f.type.startsWith('image/'));
        handleFiles(files);
    });
};

const handleFileSelect = (e) => {
    const files = Array.from(e.target.files);
    handleFiles(files);
};

const handleFiles = (files) => {
    const maxSize = 10 * 1024 * 1024; // 10MB
    
    files.forEach(file => {
        if (file.size > maxSize) {
            showToast(`Photo ${file.name} trop grande (max 10MB)`, 'error');
            return;
        }
        
        if (!file.type.match(/^image\/(jpeg|png|webp|jpg)$/)) {
            showToast(`Type non supporté: ${file.name}`, 'error');
            return;
        }
        
        uploadedPhotos.push(file);
        addPhotoPreview(file);
    });
    
    updatePhotoCount();
};

const addPhotoPreview = (file) => {
    const container = document.getElementById('photos-preview');
    
    const reader = new FileReader();
    reader.onload = (e) => {
        const div = document.createElement('div');
        div.className = 'photo-preview-item';
        div.dataset.filename = file.name;
        div.innerHTML = `
            <img src="${e.target.result}" alt="${file.name}">
            <button type="button" class="remove-btn" onclick="removePhoto('${file.name}')">×</button>
            <div class="upload-progress" style="display:none">
                <div class="upload-progress-bar" style="width:0%"></div>
            </div>
        `;
        container.appendChild(div);
    };
    reader.readAsDataURL(file);
};

window.removePhoto = (filename) => {
    uploadedPhotos = uploadedPhotos.filter(f => f.name !== filename);
    const item = document.querySelector(`.photo-preview-item[data-filename="${filename}"]`);
    if (item) item.remove();
    updatePhotoCount();
};

const updatePhotoCount = () => {
    const dropzone = document.getElementById('photo-dropzone');
    const text = dropzone.querySelector('p');
    if (uploadedPhotos.length > 0) {
        text.textContent = `${uploadedPhotos.length} photo(s) sélectionnée(s)`;
    } else {
        text.textContent = 'Cliquez ou glissez-déposez vos photos ici';
    }
};

const uploadPhotosToStorage = async (propertyId) => {
    if (uploadedPhotos.length === 0) return [];
    
    const urls = [];
    
    for (let i = 0; i < uploadedPhotos.length; i++) {
        const file = uploadedPhotos[i];
        const ext = file.name.split('.').pop();
        const path = `properties/${proprietaireId}/${propertyId}/${i}_${Date.now()}.${ext}`;
        
        try {
            const { error: uploadError } = await supabaseClient.storage
                .from('proprietes-photos')
                .upload(path, file, { 
                    contentType: file.type,
                    upsert: true 
                });
            
            if (uploadError) {
                console.warn('Upload error:', uploadError);
                continue;
            }
            
            const { data: { publicUrl } } = supabaseClient.storage
                .from('proprietes-photos')
                .getPublicUrl(path);
            
            urls.push(publicUrl);
            
            // Update progress bar
            const item = document.querySelector(`.photo-preview-item[data-filename="${file.name}"]`);
            if (item) {
                item.querySelector('.upload-progress').style.display = 'block';
                item.querySelector('.upload-progress-bar').style.width = '100%';
            }
            
        } catch (err) {
            console.error('Error uploading photo:', err);
        }
    }
    
    return urls;
};

document.addEventListener('DOMContentLoaded', async () => {
    await initAuth();
    initForm();
    initPhotoUpload();
    initLogout();
});
