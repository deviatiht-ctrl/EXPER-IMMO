import { apiClient } from '../api-client.js';

let allUsers = [];

document.addEventListener('DOMContentLoaded', async () => {
    await loadUsers();
    setupFilters();
});

async function loadUsers() {
    try {
        // Fetch all users from admin endpoint
        const data = await apiClient.get('/admin/users').catch(() => []);
        allUsers = Array.isArray(data) ? data : [];
        renderTable(allUsers);
    } catch (err) { console.error(err); }
}

function renderTable(users) {
    const tbody = document.getElementById('users-table');
    if (!tbody) return;
    
    tbody.innerHTML = users.map(u => `
        <tr>
            <td>
                <div style="display:flex; align-items:center; gap:10px;">
                    <div style="width:32px; height:32px; border-radius:50%; background:#eee; display:flex; align-items:center; justify-content:center; font-size:12px; font-weight:700;">
                        ${(u.full_name || 'U').charAt(0).toUpperCase()}
                    </div>
                    <strong>${u.full_name || 'N/A'}</strong>
                </div>
            </td>
            <td>${u.email || 'N/A'}</td>
            <td><span class="status-badge ${u.role}">${u.role}</span></td>
            <td>${new Date(u.created_at).toLocaleDateString()}</td>
            <td><span class="status-badge actif">Compte actif</span></td>
        </tr>
    `).join('');
    if (typeof lucide !== 'undefined') lucide.createIcons();
}

function setupFilters() {
    const search = document.getElementById('util-search');
    const filter = document.getElementById('filter-role');

    const apply = () => {
        let filtered = allUsers;
        if (search.value) {
            filtered = filtered.filter(u => u.full_name?.toLowerCase().includes(search.value.toLowerCase()) || u.email?.toLowerCase().includes(search.value.toLowerCase()));
        }
        if (filter.value) {
            filtered = filtered.filter(u => u.role === filter.value);
        }
        renderTable(filtered);
    };

    search?.addEventListener('input', apply);
    filter?.addEventListener('change', apply);
}
