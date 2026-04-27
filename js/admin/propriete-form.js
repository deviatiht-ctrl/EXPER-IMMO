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
    let uploadedUrls = [];  // URLs already uploaded to backend

    const IMG_API_URL = window.EXPER_API_URL || 'https://exper-immo.onrender.com';

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

            // Create preview placeholder immediately
            const previewItem = document.createElement('div');
            previewItem.className = 'preview-item';
            previewItem.style.cssText = 'position:relative;overflow:hidden;border-radius:8px;background:#f1f5f9;';
            previewItem.innerHTML = `
                <div style="height:80px;display:flex;align-items:center;justify-content:center;color:#94a3b8;font-size:12px;">Upload...</div>
            `;
            uploadPreview.appendChild(previewItem);

            // Show local preview
            const reader = new FileReader();
            reader.onload = (e) => {
                previewItem.innerHTML = `
                    <img src="${e.target.result}" alt="${file.name}" style="width:100%;height:80px;object-fit:cover;">
                    <div style="position:absolute;bottom:0;left:0;right:0;background:rgba(0,0,0,0.5);color:#fff;font-size:10px;padding:2px 4px;text-align:center;">Upload en cours...</div>
                `;
            };
            reader.readAsDataURL(file);

            // Upload to backend immediately
            uploadSingleFile(file, previewItem);
        });
    }

    async function uploadSingleFile(file, previewItem) {
        try {
            const fd = new FormData();
            fd.append('file', file);
            const token = localStorage.getItem('exper_immo_token');
            const res = await fetch(`${IMG_API_URL}/upload/image`, {
                method: 'POST',
                headers: token ? { 'Authorization': `Bearer ${token}` } : {},
                body: fd
            });
            if (res.ok) {
                const data = await res.json();
                uploadedUrls.push(data.url);
                // Update overlay to show success
                const overlay = previewItem.querySelector('div[style*="bottom:0"]');
                if (overlay) {
                    overlay.textContent = '\u2713 Uploadé';
                    overlay.style.background = 'rgba(34,197,94,0.8)';
                }
                showToast(`Image uploadée (${uploadedUrls.length} total)`, 'success');
            } else {
                const errData = await res.json().catch(() => ({}));
                const msg = errData.detail || `Erreur ${res.status}`;
                previewItem.style.outline = '2px solid #dc2626';
                const overlay = previewItem.querySelector('div[style*="bottom:0"]');
                if (overlay) { overlay.textContent = '\u2717 Échec'; overlay.style.background = 'rgba(220,38,38,0.8)'; }
                showToast(`Upload échoué: ${msg}`, 'error');
                console.error('Upload failed:', res.status, msg);
            }
        } catch (err) {
            console.error('Upload error:', err);
            showToast('Erreur réseau lors de l\'upload', 'error');
        }
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
            // 1. Prepare data (images already uploaded on selection)
            const slug = titre.toLowerCase()
                .normalize("NFD").replace(/[\u0300-\u036f]/g, "") 
                .replace(/\s+/g, '-')
                .replace(/[^\w-]/g, '')
                .replace(/--+/g, '-')
                + '-' + Date.now().toString().slice(-4);

            const formData = {
                titre: titre,
                type_transaction: document.getElementById('type_transaction').value,
                type_bien: document.getElementById('type_propriete').value,
                description: document.getElementById('description').value,
                prix: parseFloat(document.getElementById('prix_vente').value || document.getElementById('prix_location').value) || 0,
                statut_bien: document.getElementById('statut').value || 'disponible',
                devise: document.getElementById('devise').value,
                nb_chambres: parseInt(document.getElementById('nb_chambres').value) || 0,
                nb_salles_bain: parseInt(document.getElementById('nb_salles_bain').value) || 0,
                superficie_m2: parseFloat(document.getElementById('superficie_m2').value) || 0,
                est_vedette: document.getElementById('est_vedette').checked,
                adresse: document.getElementById('adresse').value,
                reference: 'REF-' + Date.now().toString().slice(-6),
                images: uploadedUrls
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
