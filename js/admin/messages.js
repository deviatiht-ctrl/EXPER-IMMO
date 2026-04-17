import CONFIG from '../config.js';
const { createClient } = supabase;
const supabaseClient = createClient(CONFIG.SUPABASE_URL, CONFIG.SUPABASE_ANON_KEY);

const messagesList = document.getElementById('messages-list');
const messageDetail = document.getElementById('message-detail');
const formNewMessage = document.getElementById('form-new-message');

document.addEventListener('DOMContentLoaded', async () => {
    const { data: { user } } = await supabaseClient.auth.getUser();
    if (!user) {
        window.location.href = '../login.html';
        return;
    }

    await loadDestinataires();
    await loadMessages();

    formNewMessage.addEventListener('submit', sendMessage);
});

async function loadDestinataires() {
    // On charge tous les profils (Propriétaires, Locataires, Gestionnaires)
    const { data: profiles } = await supabaseClient
        .from('profiles')
        .select('id, full_name, role')
        .order('full_name');
    
    if (profiles) {
        const select = document.getElementById('msg-destinataire');
        select.innerHTML = '<option value="">Choisir un destinataire...</option>' + 
            profiles.map(p => `<option value="${p.id}">${p.full_name} (${p.role})</option>`).join('');
    }
}

async function loadMessages() {
    messagesList.innerHTML = '<p class="empty-state">Chargement...</p>';
    
    const { data, error } = await supabaseClient
        .from('messages')
        .select(`
            *,
            expediteur:profiles!messages_expediteur_fkey(full_name, role)
        `)
        .order('date_envoi', { ascending: false });

    if (error) {
        messagesList.innerHTML = '<p class="empty-state">Erreur de chargement.</p>';
        return;
    }

    if (!data || data.length === 0) {
        messagesList.innerHTML = '<p class="empty-state">Aucun message.</p>';
        return;
    }

    messagesList.innerHTML = data.map(msg => `
        <div class="activity-item ${msg.lu_oui_non ? '' : 'unread'}" onclick="viewMessage('${msg.id_message}')" style="cursor:pointer;">
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
    
    lucide.createIcons();
}

function getRoleColor(role) {
    if (role === 'admin') return '#fee2e2';
    if (role === 'proprietaire') return '#dbeafe';
    if (role === 'locataire') return '#d1fae5';
    return '#f1f5f9';
}

async function sendMessage(e) {
    e.preventDefault();
    const { data: { user } } = await supabaseClient.auth.getUser();
    
    const msgData = {
        expediteur: user.id,
        destinataire: document.getElementById('msg-destinataire').value,
        objet: document.getElementById('msg-objet').value,
        message: document.getElementById('msg-content').value,
        statut_message: 'nouveau'
    };

    const { error } = await supabaseClient.from('messages').insert([msgData]);

    if (error) {
        alert("Erreur: " + error.message);
    } else {
        window.closeModal('new-message');
        formNewMessage.reset();
        await loadMessages();
    }
}

window.viewMessage = async (id) => {
    const { data: msg } = await supabaseClient
        .from('messages')
        .select('*, expediteur:profiles!messages_expediteur_fkey(full_name)')
        .eq('id_message', id)
        .single();
    
    if (msg) {
        messageDetail.innerHTML = `
            <div class="message-view">
                <div class="message-meta" style="margin-bottom: 20px; border-bottom: 1px solid #eee; padding-bottom: 10px;">
                    <strong>De :</strong> ${msg.expediteur.full_name}<br>
                    <strong>Objet :</strong> ${msg.objet}<br>
                    <strong>Date :</strong> ${new Date(msg.date_envoi).toLocaleString()}
                </div>
                <div class="message-body" style="line-height: 1.6; font-size: 15px;">
                    ${msg.message}
                </div>
            </div>
        `;
        // Mark as read
        await supabaseClient.from('messages').update({ lu_oui_non: true }).eq('id_message', id);
    }
};
