import apiClient from '../api-client.js';

document.addEventListener('DOMContentLoaded', async () => {
    await checkAuth();
    await loadPersonnel();
    setupForm();
    if (typeof lucide !== 'undefined') lucide.createIcons();
});

function checkAuth() {
    const userStr = localStorage.getItem('exper_immo_user');
    if (!userStr) { window.location.href = '../login.html'; return; }
    const user = JSON.parse(userStr);
    if (user.role !== 'admin') { window.location.href = '../index.html'; }
}

async function loadPersonnel() {
    const tbody = document.getElementById('personnel-table');
    if (tbody) tbody.innerHTML = '<tr><td colspan="5" style="text-align:center">Chargement...</td></tr>';
    try {
        const data = await apiClient.get('/admin/gestionnaires');
        renderTable(data || []);
    } catch (err) {
        console.error(err);
        if (tbody) tbody.innerHTML = `<tr><td colspan="5" style="color:red">Erreur: ${err.message}</td></tr>`;
    }
}

function renderTable(users) {
    const tbody = document.getElementById('personnel-table');
    if (!tbody) return;
    if (!users.length) {
        tbody.innerHTML = '<tr><td colspan="5" style="text-align:center;padding:30px;color:#64748b;">Aucun membre du personnel</td></tr>';
        return;
    }
    const roleColors = { admin: '#dc2626', gestionnaire: '#2563eb', assistante: '#7c3aed' };
    tbody.innerHTML = users.map(u => {
        const color = roleColors[u.role] || '#64748b';
        return `<tr>
            <td><strong>${esc(u.full_name || 'N/A')}</strong></td>
            <td>${esc(u.email || 'N/A')}</td>
            <td><span style="background:${color}20;color:${color};padding:3px 10px;border-radius:20px;font-size:12px;font-weight:600;">${u.role}</span></td>
            <td><span style="font-size:12px;color:#64748b;">${u.created_at ? new Date(u.created_at).toLocaleDateString('fr-FR') : 'N/A'}</span></td>
            <td>
                <button class="action-btn delete" onclick="deletePersonnel('${u.id}', '${esc(u.full_name || '')}')">
                    <i data-lucide="trash-2"></i>
                </button>
            </td>
        </tr>`;
    }).join('');
    if (typeof lucide !== 'undefined') lucide.createIcons();
}

function setupForm() {
    const form = document.getElementById('gest-form');
    if (!form) return;
    form.addEventListener('submit', async (e) => {
        e.preventDefault();
        const btn = form.querySelector('button[type="submit"]');
        btn.disabled = true;
        btn.textContent = 'Création en cours...';
        try {
            const payload = {
                nom:      document.getElementById('gest-nom')?.value.trim()    || '',
                prenom:   document.getElementById('gest-prenom')?.value.trim() || '',
                email:    document.getElementById('gest-email')?.value.trim()  || '',
                password: document.getElementById('gest-password')?.value      || '',
                role:     document.getElementById('gest-role')?.value          || 'gestionnaire',
                phone:    document.getElementById('gest-phone')?.value.trim()  || undefined,
            };
            if (!payload.nom || !payload.prenom || !payload.email || !payload.password) {
                showFeedback('Tous les champs obligatoires doivent être remplis.', 'error');
                return;
            }
            await apiClient.post('/admin/gestionnaires', payload);
            showFeedback(`Compte créé pour ${payload.prenom} ${payload.nom}`, 'success');
            form.reset();
            closeModal('add-gestionnaire');
            await loadPersonnel();
        } catch (err) {
            showFeedback(err.message || 'Erreur lors de la création', 'error');
        } finally {
            btn.disabled = false;
            btn.textContent = 'Créer le compte';
        }
    });
}

window.deletePersonnel = async (id, name) => {
    if (!confirm(`Supprimer le compte de ${name} ?`)) return;
    try {
        await apiClient.delete(`/admin/gestionnaires/${id}`);
        await loadPersonnel();
    } catch (err) {
        alert('Erreur: ' + err.message);
    }
};

window.openModal  = (id) => { const m = document.getElementById(id); if (m) m.style.display = 'flex'; };
window.closeModal = (id) => { const m = document.getElementById(id); if (m) m.style.display = 'none'; };

function esc(s) { return String(s || '').replace(/&/g,'&amp;').replace(/</g,'&lt;').replace(/>/g,'&gt;'); }
function showFeedback(msg, type) {
    if (window.showToast) { window.showToast(msg, type); return; }
    alert(msg);
}
