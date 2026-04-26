// admin/propriete-form.js
import apiClient from '../api-client.js';

function showToast(msg, type) {
    type = type || 'info';
    var t = document.createElement('div');
    t.className = 'toast toast-' + type;
    t.innerHTML = '<i data-lucide="' + (type==='success'?'check-circle':type==='error'?'alert-circle':'info') + '"></i><span>' + String(msg) + '</span>';
    document.body.appendChild(t);
    if (typeof lucide !== 'undefined') lucide.createIcons();
    setTimeout(function(){ t.remove(); }, 5000);
}

document.addEventListener('DOMContentLoaded', async () => {
    const urlParams = new URLSearchParams(window.location.search);
    const propId = urlParams.get('id');
    const form = document.getElementById('prop-form');
    const btnSave = document.getElementById('btn-save-prop');

    // Load Dropdowns
    const loadDropdowns = async () => {
        try {
            const zones = await apiClient.get('/zones');
            const agents = await apiClient.get('/agents');

            const zoneSelect = document.getElementById('zone_id');
            const agentSelect = document.getElementById('agent_id');

            zones?.forEach(z => zoneSelect.innerHTML += `<option value="${z.id}">${z.nom}</option>`);
            agents?.forEach(a => agentSelect.innerHTML += `<option value="${a.id}">${a.prenom} ${a.nom}</option>`);
        } catch (e) {
            console.error("Dropdowns error:", e);
        }
    };

    // Load Data if Edit
    const loadPropData = async () => {
        if (!propId) return;
        document.getElementById('form-title').textContent = "Modifier la Propriété";
        
        try {
            // Note: If using ID, we might need a /properties/id/{id} endpoint
            // For now, let's assume we can fetch by slug or implement a get-by-id
            const p = await apiClient.get(`/properties/id/${propId}`);

            // Populate fields
            document.getElementById('titre').value = p.titre;
            document.getElementById('type_transaction').value = p.type_transaction;
            document.getElementById('type_propriete').value = p.type_propriete;
            document.getElementById('description').value = p.description;
            document.getElementById('prix_location').value = p.prix_location || '';
            document.getElementById('prix_vente').value = p.prix_vente || '';
            document.getElementById('statut').value = p.statut || 'disponible';
            document.getElementById('devise').value = p.devise || 'USD';
            document.getElementById('nb_chambres').value = p.nb_chambres;
            document.getElementById('nb_salles_bain').value = p.nb_salles_bain;
            document.getElementById('nb_garages').value = p.nb_garages;
            document.getElementById('superficie_m2').value = p.superficie_m2;
            document.getElementById('est_vedette').checked = p.est_vedette;
            document.getElementById('zone_id').value = p.zone_id;
            document.getElementById('agent_id').value = p.agent_id;
            document.getElementById('adresse').value = p.adresse || '';
        } catch (e) {
            console.error("Load prop error:", e);
        }
    };

    // Logout
    document.getElementById('btn-logout')?.addEventListener('click', () => {
        localStorage.removeItem('exper_immo_token');
        localStorage.removeItem('exper_immo_user');
        window.location.href = '../login.html';
    });

    // Image Upload & Preview Logic
    const uploadZone = document.getElementById('upload-zone');
    const fileInput = document.getElementById('file-input');
    const uploadPreview = document.getElementById('upload-preview');
    let uploadedFiles = [];

    uploadZone.addEventListener('click', () => fileInput.click());

    uploadZone.addEventListener('dragover', (e) => {
        e.preventDefault();
        uploadZone.classList.add('dragover');
    });

    ['dragleave', 'drop'].forEach(event => {
        uploadZone.addEventListener(event, () => uploadZone.classList.remove('dragover'));
    });

    uploadZone.addEventListener('drop', (e) => {
        e.preventDefault();
        handleFiles(e.dataTransfer.files);
    });

    fileInput.addEventListener('change', () => handleFiles(fileInput.files));

    function handleFiles(files) {
        Array.from(files).forEach(file => {
            if (!file.type.startsWith('image/')) return;
            
            const reader = new FileReader();
            reader.onload = (e) => {
                const previewItem = document.createElement('div');
                previewItem.className = 'preview-item';
                previewItem.innerHTML = `
                    <img src="${e.target.result}" alt="${file.name}">
                    <div class="preview-overlay">
                        <span class="preview-name">${file.name}</span>
                    </div>
                `;
                uploadPreview.appendChild(previewItem);
            };
            reader.readAsDataURL(file);
            uploadedFiles.push(file);
        });
        showToast(`${files.length} image(s) ajoutée(s) au local`, "info");
    }

    btnSave.addEventListener('click', async (e) => {
        e.preventDefault();
        
        // Basic Validation
        const titre = document.getElementById('titre').value;
        if (!titre) { showToast("Le titre est requis", "warning"); return; }
        
        const originalText = btnSave.innerHTML;
        btnSave.disabled = true;
        btnSave.innerHTML = '<i class="spinner-small"></i> <span>Enregistrement...</span>';

        try {
            // 1. Prepare data
            const slug = titre.toLowerCase()
                .normalize("NFD").replace(/[\u0300-\u036f]/g, "") 
                .replace(/\s+/g, '-')
                .replace(/[^\w-]/g, '')
                .replace(/--+/g, '-')
                + '-' + Date.now().toString().slice(-4);

            const formData = {
                titre: titre,
                type_transaction: document.getElementById('type_transaction').value,
                type_propriete: document.getElementById('type_propriete').value,
                description: document.getElementById('description').value,
                prix: parseFloat(document.getElementById('prix_vente').value || document.getElementById('prix_location').value) || 0,
                prix_location: parseFloat(document.getElementById('prix_location').value) || null,
                prix_vente: parseFloat(document.getElementById('prix_vente').value) || null,
                statut_bien: document.getElementById('statut').value || 'disponible',
                devise: document.getElementById('devise').value,
                nb_chambres: parseInt(document.getElementById('nb_chambres').value) || 0,
                nb_salles_bain: parseInt(document.getElementById('nb_salles_bain').value) || 0,
                nb_garages: parseInt(document.getElementById('nb_garages').value) || 0,
                superficie_m2: parseFloat(document.getElementById('superficie_m2').value) || 0,
                est_vedette: document.getElementById('est_vedette').checked,
                zone_id: document.getElementById('zone_id').value || null,
                agent_id: document.getElementById('agent_id').value || null,
                adresse: document.getElementById('adresse').value,
                reference: 'REF-' + Date.now().toString().slice(-6)
            };

            if (!propId) formData.slug = slug;

            let result;
            if (propId) {
                result = await apiClient.put(`/properties/${propId}`, formData);
            } else {
                result = await apiClient.post('/properties', formData);
            }

            showToast(propId ? "Propriété mise à jour !" : "Propriété créée avec succès !", "success");
            
            setTimeout(() => {
                window.location.href = 'proprietes.html';
            }, 1000);

        } catch (error) {
            console.error("Save error:", error);
            showToast(error.message || "Erreur lors de l'enregistrement", "error");
            btnSave.disabled = false;
            btnSave.innerHTML = originalText;
        }
    });

    await loadDropdowns();
    await loadPropData();
});
