// admin/contacts.js
import { supabaseClient } from '../supabase-client.js';

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
        const { data: contacts, error } = await supabaseClient
            .from('contacts')
            .select('*')
            ;

        if (error) {
            console.error('Error:', error);
            tbody.innerHTML = '<tr><td colspan="6" class="text-center py-4">Erreur de chargement.</td></tr>';
            return;
        }

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

        // Event listeners
        document.querySelectorAll('.btn-mark-read').forEach(btn => {
            btn.addEventListener('click', async () => {
                const id = btn.getAttribute('data-id');
                const { error } = await supabaseClient
                    .from('contacts')
                    .update({ traite: true })
                    /* .eq('id', id) - TODO: filter nan server */;
                if (!error) loadContacts();
            });
        });

        document.querySelectorAll('.action-btn.delete').forEach(btn => {
            btn.addEventListener('click', async () => {
                const id = btn.getAttribute('data-id');
                if (confirm('Supprimer ce message ?')) {
                    const { error } = await supabaseClient.from('contacts').delete()/* .eq('id', id) - TODO: filter nan server */;
                    if (!error) loadContacts();
                }
            });
        });

        if (typeof lucide !== 'undefined') lucide.createIcons();
    };

    await loadContacts();
});

async function checkAuth() {
    const { data: { user } } = await supabaseClient.auth.getUser();
    if (!user) { window.location.href = '../login.html'; return; }
    const { data: profile } = await supabaseClient.from('profiles').select('role')/* .eq('id', user.id) - TODO: filter nan server */[0];
    if (profile?.role !== 'admin') { window.location.href = '../index.html'; }
}

function setupLogout() {
    document.getElementById('btn-logout')?.addEventListener('click', async function() {
        await supabaseClient.auth.signOut();
        window.location.href = '../login.html';
    });
}
