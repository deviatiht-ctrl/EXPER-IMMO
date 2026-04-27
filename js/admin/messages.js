import { apiClient } from '../api-client.js';

const messagesList = document.getElementById('messages-list');
const messageDetail = document.getElementById('message-detail');
const formNewMessage = document.getElementById('form-new-message');

document.addEventListener('DOMContentLoaded', async () => {
    const user = JSON.parse(localStorage.getItem('exper_immo_user') || '{}');
    const token = localStorage.getItem('exper_immo_token');
    
    if (!token || !user.id) {
        window.location.href = '../login.html';
        return;
    }
    
    if (user.role !== 'admin') {
        window.location.href = '../index.html';
        return;
    }

    await loadDestinataires();
    await loadMessages();

    formNewMessage?.addEventListener('submit', sendMessage);
});

async function loadDestinataires() {
    try {
        const profiles = await apiClient.get('/admin/proprietaires').catch(() => []);
        
        const select = document.getElementById('msg-destinataire');
        if (select && profiles) {
            select.innerHTML = '<option value="">Choisir un destinataire...</option>' + 
                profiles.map(p => `<option value="${p.id || p.id_user}">${p.prenom || p.nom || p.email} (proprietaire)</option>`).join('');
        }
    } catch (e) {
        console.warn('Could not load destinataires:', e);
    }
}

async function loadMessages() {
    messagesList.innerHTML = '<p class="empty-state">Chargement...</p>';
    
    try {
        // Messages endpoint may not exist yet, show placeholder
        const data = []; // await apiClient.get('/messages').catch(() => []);

        if (!data || data.length === 0) {
            messagesList.innerHTML = '<p class="empty-state">Aucun message.</p>';
            return;
        }

        messagesList.innerHTML = data.map(msg => `
            <div class="activity-item ${msg.lu_oui_non ? '' : 'unread'}" onclick="viewMessage('${msg.id || msg.id_message}')" style="cursor:pointer;">
                <div class="activity-icon" style="background: ${getRoleColor(msg.expediteur?.role)}">
                    <i data-lucide="user"></i>
                </div>
                <div class="activity-content">
                    <h4>${msg.objet}</h4>
                    <p>De: ${msg.expediteur?.full_name || 'Inconnu'}</p>
                </div>
                <span class="activity-time">${new Date(msg.date_envoi).toLocaleDateString()}</span>
            </div>
        `).join('');
        if (typeof lucide !== 'undefined') lucide.createIcons();
    } catch(err) {
        console.error(err);
        messagesList.innerHTML = '<p class="empty-state">Erreur de chargement.</p>';
    }
}

async function sendMessage(e) {
    e.preventDefault();
    const user = JSON.parse(localStorage.getItem('exper_immo_user') || '{}');
    const msgData = {
        expediteur: user.id,
        destinataire: document.getElementById('msg-destinataire').value,
        objet: document.getElementById('msg-objet').value,
        message: document.getElementById('msg-content').value,
        statut_message: 'nouveau'
    };
    try {
        await apiClient.post('/messages', msgData);
        window.closeModal?.('new-message');
        formNewMessage?.reset();
        await loadMessages();
    } catch(err) {
        alert("Erreur: " + err.message);
    }
}

window.viewMessage = async (id) => {
    if (!messageDetail) return;
    messageDetail.innerHTML = '<p>Chargement...</p>';
    // Message detail endpoint not yet implemented
    messageDetail.innerHTML = `
        <div class="message-view">
            <p style="color:#888;">Détail du message non disponible.</p>
        </div>
    `;
};

function getRoleColor(role) {
    if (role === 'admin') return '#fee2e2';
    if (role === 'proprietaire') return '#dbeafe';
    if (role === 'locataire') return '#d1fae5';
    return '#f1f5f9';
}
