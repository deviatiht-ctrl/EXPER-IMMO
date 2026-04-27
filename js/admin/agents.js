// admin/agents.js
import { apiClient } from '../api-client.js';

document.addEventListener('DOMContentLoaded', async () => {
    const tbody = document.getElementById('agents-tbody');

    const modal = document.getElementById('modal-agent');
    const form = document.getElementById('agent-form');
    const photoInput = document.getElementById('photo-input');
    const photoPreview = document.getElementById('photo-preview');
    const photoIcon = document.getElementById('photo-icon');
    const photoContainer = document.getElementById('photo-preview-container');

    checkAuth();
    setupLogout();

    window.openAgentModal = (agent = null) => {
        form.reset();
        photoPreview.style.display = 'none';
        photoIcon.style.display = 'block';
        
        if (agent) {
            document.getElementById('modal-title').textContent = "Modifier l'Agent";
            document.getElementById('agent-id').value = agent.id;
            document.getElementById('prenom').value = agent.prenom;
            document.getElementById('nom').value = agent.nom;
            document.getElementById('titre').value = agent.titre;
            document.getElementById('telephone').value = agent.telephone || '';
            document.getElementById('email').value = agent.email || '';
            document.getElementById('ordre').value = agent.ordre || 1;
            
            if (agent.photo_url) {
                photoPreview.src = agent.photo_url;
                photoPreview.style.display = 'block';
                photoIcon.style.display = 'none';
            }
        } else {
            document.getElementById('modal-title').textContent = "Nouvel Agent";
            document.getElementById('agent-id').value = '';
        }
        
        modal.classList.add('is-open');
        document.body.style.overflow = 'hidden';
        if (typeof lucide !== 'undefined') lucide.createIcons();
    };

    window.closeAgentModal = () => {
        modal.classList.remove('is-open');
        document.body.style.overflow = '';
    };

    // Photo Preview Logic
    photoContainer.onclick = () => photoInput.click();
    photoInput.onchange = (e) => {
        const file = e.target.files[0];
        if (file) {
            const reader = new FileReader();
            reader.onload = (re) => {
                photoPreview.src = re.target.result;
                photoPreview.style.display = 'block';
                photoIcon.style.display = 'none';
            };
            reader.readAsDataURL(file);
        }
    };

    const loadAgents = async () => {
        try {
            const agents = await apiClient.get('/agents');
            
            if (!agents || !agents.length) {
                tbody.innerHTML = '<tr><td colspan="5" class="text-center py-4">Aucun agent trouvé.</td></tr>';
                return;
            }

            tbody.innerHTML = '';
            agents.forEach(a => {
            const tr = document.createElement('tr');
            tr.innerHTML = `
                <td><img src="${a.photo_url || 'https://i.pravatar.cc/150'}" class="table-thumb" style="border-radius:50%;width:40px;height:40px;object-fit:cover"></td>
                <td style="font-weight:600">${a.prenom} ${a.nom}</td>
                <td>${a.titre}</td>
                <td>${a.telephone || '-'}</td>
                <td class="actions">
                    <button class="action-btn edit" title="Modifier"><i data-lucide="edit-2"></i></button>
                    <button class="action-btn delete" title="Supprimer"><i data-lucide="trash-2"></i></button>
                </td>
            `;
            
            tr.querySelector('.edit').onclick = () => openAgentModal(a);
            tr.querySelector('.delete').onclick = () => deleteAgent(a.id);
            
            tbody.appendChild(tr);
        });

            if (typeof lucide !== 'undefined') lucide.createIcons();
        } catch (err) {
            console.error('Error:', err);
            tbody.innerHTML = '<tr><td colspan="5" class="text-center py-4">Erreur de chargement.</td></tr>';
        }
    };

    const deleteAgent = async (id) => {
        if (confirm('Voulez-vous vraiment supprimer cet agent ?')) {
            try {
                await apiClient.delete('/agents/' + id);
                loadAgents();
            } catch (err) {
                alert('Erreur lors de la suppression.');
            }
        }
    };

    form.onsubmit = async (e) => {
        e.preventDefault();
        const btnSave = document.getElementById('btn-save-agent');
        const originalText = btnSave.innerHTML;
        btnSave.disabled = true;
        btnSave.innerHTML = '<span class="spinner-small"></span>';

        const agentId = document.getElementById('agent-id').value;
        const photoFile = photoInput.files[0];
        let photoUrl = photoPreview.src.startsWith('http') ? photoPreview.src : null;

        try {
            // 1. Upload Photo if changed
            let photoUrl = photoPreview.src.startsWith('http') ? photoPreview.src : null;
            if (photoFile) {
                const formData = new FormData();
                formData.append('file', photoFile);
                const uploadResult = await apiClient.post('/upload/image', formData, false);
                photoUrl = uploadResult.url;
            }

            // 2. Save Agent Data
            const agentData = {
                prenom: document.getElementById('prenom').value,
                nom: document.getElementById('nom').value,
                titre: document.getElementById('titre').value,
                telephone: document.getElementById('telephone').value,
                email: document.getElementById('email').value,
                ordre: parseInt(document.getElementById('ordre').value) || 1,
                photo_url: photoUrl
            };

            if (agentId) {
                await apiClient.put('/agents/' + agentId, agentData);
            } else {
                await apiClient.post('/agents', agentData);
            }

            closeAgentModal();
            loadAgents();
        } catch (err) {
            alert("Erreur: " + err.message);
        } finally {
            btnSave.disabled = false;
            btnSave.innerHTML = originalText;
            if (typeof lucide !== 'undefined') lucide.createIcons();
        }
    };

    modal.addEventListener('click', function(e) { if (e.target === modal) closeAgentModal(); });

    await loadAgents();
});

function checkAuth() {
    const user = JSON.parse(localStorage.getItem('exper_immo_user') || '{}');
    const token = localStorage.getItem('exper_immo_token');
    if (!token || !user.id) { window.location.href = '../login.html'; return; }
    if (user.role !== 'admin') { window.location.href = '../index.html'; }
}

function setupLogout() {
    document.getElementById('btn-logout')?.addEventListener('click', function() {
        localStorage.removeItem('exper_immo_token');
        localStorage.removeItem('exper_immo_user');
        window.location.href = '../login.html';
    });
}
