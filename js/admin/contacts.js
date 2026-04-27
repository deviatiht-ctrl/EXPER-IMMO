// admin/contacts.js
import { apiClient } from '../api-client.js';

document.addEventListener('DOMContentLoaded', async () => {
    await checkAuth();
    setupLogout();
    const tbody = document.getElementById('contacts-tbody');

    document.getElementById('search-contacts')?.addEventListener('input', function(e) {
        const q = e.target.value.toLowerCase();
        document.querySelectorAll('#contacts-tbody tr').forEach(function(r) {
            r.style.display = r.textContent.toLowerCase().includes(q) ? '' : 'none';
        });
    });

    const loadContacts = async () => {
        try {
            // Contacts endpoint may not exist yet, show placeholder
            const contacts = []; // await apiClient.get('/contacts').catch(() => []);
            
            if (!contacts || contacts.length === 0) {
                tbody.innerHTML = '<tr><td colspan="6" class="text-center py-4">Aucun message trouvé.</td></tr>';
                return;
            }

            tbody.innerHTML = '';
            contacts.forEach(c => {
                const tr = document.createElement('tr');
                tr.innerHTML = `
                    <td style="font-size:12px">${new Date(c.created_at).toLocaleDateString()}</td>
                    <td style="font-weight:600">${c.nom}</td>
                    <td><a href="mailto:${c.email}" style="color:var(--admin-accent)">${c.email}</a></td>
                    <td>${c.sujet || 'Demande Info'}</td>
                    <td><span class="status-badge ${c.traite ? 'actif' : 'pending'}">${c.traite ? 'Traité' : 'Nouveau'}</span></td>
                    <td class="actions">
                        <button class="action-btn view btn-mark-read" data-id="${c.id}" ${c.traite ? 'disabled style="opacity:0.3"' : ''} title="Marquer comme lu"><i data-lucide="check"></i></button>
                        <button class="action-btn delete" data-id="${c.id}" title="Supprimer"><i data-lucide="trash-2"></i></button>
                    </td>
                `;
                tbody.appendChild(tr);
            });

            if (typeof lucide !== 'undefined') lucide.createIcons();
        } catch (error) {
            console.error('Error loading contacts:', error);
            tbody.innerHTML = '<tr><td colspan="6" class="text-center py-4">Erreur de chargement.</td></tr>';
        }
    };

    await loadContacts();
});

async function checkAuth() {
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
