// proprietaire-add-property.js - Add Property Page
import { showToast, formatPrice } from './utils.js';
import { requireAuth, logout } from './auth.js';
import apiClient from './api-client.js';

let currentUser = null;
let proprietaireId = null;
let uploadedPhotos = []; // Store selected files

const initAuth = async () => {
    const userStr = localStorage.getItem('exper_immo_user');
    if (!userStr) { window.location.href = '../login.html'; return; }
    currentUser = JSON.parse(userStr);
    if (currentUser.role !== 'proprietaire') { window.location.href = '../login.html'; return; }

    const nameEl   = document.getElementById('user-name');
    const avatarEl = document.getElementById('user-avatar');
    if (nameEl)   nameEl.textContent   = currentUser.full_name || 'Propriétaire';
    if (avatarEl) avatarEl.textContent = (currentUser.full_name || 'P').charAt(0).toUpperCase();
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
        
        // Insert via API
        const data = await apiClient.post('/properties', formData);
        if (!data || !data.id) throw new Error('Erreur lors de l\'enregistrement');
        
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

const uploadPhotosToStorage = async (_propertyId) => {
    if (uploadedPhotos.length === 0) return [];

    const token = localStorage.getItem('exper_immo_token');
    const API_URL = window.EXPER_API_URL || 'https://exper-immo.onrender.com';
    const urls = [];

    for (let i = 0; i < uploadedPhotos.length; i++) {
        const file = uploadedPhotos[i];
        const item = document.querySelector(`.photo-preview-item[data-filename="${file.name}"]`);

        try {
            const form = new FormData();
            form.append('file', file);

            const resp = await fetch(`${API_URL}/upload/image`, {
                method: 'POST',
                headers: token ? { 'Authorization': `Bearer ${token}` } : {},
                body: form,
            });

            if (!resp.ok) {
                const err = await resp.json().catch(() => ({}));
                console.warn('Upload error:', err.detail || resp.status);
                continue;
            }

            const result = await resp.json();
            urls.push(result.url);

            if (item) {
                const bar = item.querySelector('.upload-progress');
                const fill = item.querySelector('.upload-progress-bar');
                if (bar)  bar.style.display = 'block';
                if (fill) fill.style.width = '100%';
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
