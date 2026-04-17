import { supabaseClient as supabase } from '../supabase-client.js';

document.addEventListener('DOMContentLoaded', async () => {
    await loadPersonnel();
});

async function loadPersonnel() {
    try {
        const { data, error } = await supabase
            .from('profiles')
            .select('*')
            .in('role', ['admin', 'gestionnaire', 'assistante'])
            .order('full_name');

        if (error) throw error;
        renderTable(data || []);
    } catch (err) { console.error(err); }
}

function renderTable(users) {
    const tbody = document.getElementById('personnel-table');
    if (!tbody) return;
    tbody.innerHTML = users.map(u => `
        <tr>
            <td><strong>${u.full_name || 'N/A'}</strong></td>
            <td>${u.email || 'N/A'}</td>
            <td><span class="status-badge ${u.role}">${u.role}</span></td>
            <td>${u.derniere_connexion ? new Date(u.derniere_connexion).toLocaleString() : 'Jamais'}</td>
            <td>
                <button class="action-btn delete" onclick="deleteUser('${u.id}')">Supprimer</button>
            </td>
        </tr>
    `).join('');
}

window.openModal = (id) => document.getElementById(id).classList.add('is-open');
window.closeModal = (id) => document.getElementById(id).classList.remove('is-open');
