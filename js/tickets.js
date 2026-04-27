// tickets.js - Support Tickets Page (for all user types)
import { apiClient } from './api-client.js';
import { showToast } from './utils.js';

let currentUser = null;
let userRole = null;
let allTickets = [];
let currentTicketId = null;

const initAuth = () => {
    const user = JSON.parse(localStorage.getItem('exper_immo_user') || '{}');
    const token = localStorage.getItem('exper_immo_token');
    if (!token || !user.id) { window.location.href = '../login.html'; return false; }
    
    currentUser = user;
    userRole = user.role;
    
    // Setup sidebar based on role
    setupSidebar();
    
    const name = (`${user.prenom || ''} ${user.nom || ''}`).trim() || user.email || 'Utilisateur';
    const el = document.getElementById('user-name');
    if (el) el.textContent = name;
    const av = document.getElementById('user-avatar');
    if (av) av.textContent = name.charAt(0).toUpperCase();
    const roleEl = document.getElementById('user-role');
    if (roleEl) roleEl.textContent = userRole === 'proprietaire' ? 'Propriétaire' : userRole === 'locataire' ? 'Locataire' : 'Admin';
    return true;
};

const setupSidebar = () => {
    const sidebar = document.getElementById('sidebar');
    const nav = document.getElementById('portal-nav');
    
    sidebar.classList.add(userRole);
    
    if (userRole === 'proprietaire') {
        nav.innerHTML = `
            <div class="portal-nav-section">
                <h5>Menu Principal</h5>
                <a href="proprietaire/index.html">
                    <i data-lucide="layout-dashboard"></i> Tableau de bord
                </a>
                <a href="proprietaire/mes-proprietes.html">
                    <i data-lucide="building-2"></i> Mes Propriétés
                </a>
                <a href="proprietaire/contrats.html">
                    <i data-lucide="file-text"></i> Contrats
                </a>
                <a href="proprietaire/paiements.html">
                    <i data-lucide="wallet"></i> Paiements
                </a>
            </div>
            <div class="portal-nav-section">
                <h5>Support</h5>
                <a href="tickets.html" class="active">
                    <i data-lucide="help-circle"></i> Support
                </a>
            </div>
        `;
    } else if (userRole === 'locataire') {
        nav.innerHTML = `
            <div class="portal-nav-section">
                <h5>Menu Principal</h5>
                <a href="locataire/index.html">
                    <i data-lucide="layout-dashboard"></i> Tableau de bord
                </a>
                <a href="locataire/mon-contrat.html">
                    <i data-lucide="file-text"></i> Mon Contrat
                </a>
                <a href="locataire/mes-paiements.html">
                    <i data-lucide="wallet"></i> Mes Paiements
                </a>
            </div>
            <div class="portal-nav-section">
                <h5>Support</h5>
                <a href="tickets.html" class="active">
                    <i data-lucide="help-circle"></i> Support
                </a>
            </div>
        `;
    }
    
    lucide.createIcons();
};

const loadTickets = async () => {
    try {
        // Tickets endpoint may not exist yet
        allTickets = []; // await apiClient.get('/tickets').catch(() => []);
        renderTickets(allTickets);
        updateStats(allTickets);
        
    } catch (error) {
        console.error('Error loading tickets:', error);
        showToast('Erreur lors du chargement des tickets', 'error');
    }
};

const renderTickets = (tickets) => {
    const list = document.getElementById('tickets-list');
    const emptyState = document.getElementById('empty-state');
    
    if (!tickets || tickets.length === 0) {
        list.innerHTML = '';
        emptyState.style.display = 'block';
        return;
    }
    
    emptyState.style.display = 'none';
    
    list.innerHTML = tickets.map(t => `
        <div class="ticket-item" onclick="openTicketDetail('${t.id}')">
            <div class="ticket-header">
                <div class="ticket-info">
                    <h4>${t.sujet}</h4>
                    <span class="ticket-ref">#${t.reference}</span>
                </div>
                <span class="status-badge ${getStatusClass(t.statut)}">
                    ${getStatusLabel(t.statut)}
                </span>
            </div>
            <div class="ticket-meta">
                <span><i data-lucide="tag"></i> ${getCategorieLabel(t.categorie)}</span>
                <span><i data-lucide="flag"></i> ${getPrioriteLabel(t.priorite)}</span>
                <span><i data-lucide="calendar"></i> ${new Date(t.created_at).toLocaleDateString()}</span>
            </div>
            <p class="ticket-preview">${t.description.substring(0, 100)}...</p>
        </div>
    `).join('');
    
    lucide.createIcons();
};

const updateStats = (tickets) => {
    const total = tickets.length;
    const ouverts = tickets.filter(t => ['ouvert', 'en_cours'].includes(t.statut)).length;
    const resolus = tickets.filter(t => t.statut === 'resolu').length;
    
    document.getElementById('stat-total').textContent = total;
    document.getElementById('stat-ouverts').textContent = ouverts;
    document.getElementById('stat-resolus').textContent = resolus;
};

const getStatusClass = (statut) => {
    switch (statut) {
        case 'ouvert': return 'orange';
        case 'en_cours': return 'blue';
        case 'resolu': return 'green';
        case 'ferme': return 'gray';
        default: return 'gray';
    }
};

const getStatusLabel = (statut) => {
    switch (statut) {
        case 'ouvert': return 'Ouvert';
        case 'en_cours': return 'En cours';
        case 'resolu': return 'Résolu';
        case 'ferme': return 'Fermé';
        default: return statut;
    }
};

const getCategorieLabel = (cat) => {
    const labels = {
        maintenance: 'Maintenance',
        plomberie: 'Plomberie',
        electricite: 'Électricité',
        paiement: 'Paiement',
        bruit: 'Bruit',
        securite: 'Sécurité',
        nettoyage: 'Nettoyage',
        autre: 'Autre'
    };
    return labels[cat] || cat;
};

const getPrioriteLabel = (prio) => {
    const labels = {
        basse: 'Basse',
        moyenne: 'Moyenne',
        haute: 'Haute',
        urgente: 'Urgente'
    };
    return labels[prio] || prio;
};

const filterTickets = () => {
    const statut = document.getElementById('filter-statut').value;
    
    let filtered = allTickets;
    
    if (statut) {
        filtered = filtered.filter(t => t.statut === statut);
    }
    
    renderTickets(filtered);
};

const submitNewTicket = async () => {
    const sujet = document.getElementById('ticket-sujet').value;
    const categorie = document.getElementById('ticket-categorie').value;
    const priorite = document.getElementById('ticket-priorite').value;
    const description = document.getElementById('ticket-description').value;
    
    if (!sujet || !categorie || !description) {
        showToast('Veuillez remplir tous les champs obligatoires', 'error');
        return;
    }
    
    try {
        // Tickets endpoint not yet available
        showToast('Fonctionnalité tickets bientôt disponible', 'info');
        closeNewTicketModal();
        
    } catch (error) {
        console.error('Error creating ticket:', error);
        showToast('Erreur lors de la création du ticket', 'error');
    }
};

const loadTicketDetail = async (ticketId) => {
    currentTicketId = ticketId;
    
    try {
        const ticket = allTickets.find(t => t.id === ticketId);
        if (!ticket) { showToast('Ticket non trouvé', 'error'); return; }
        
        document.getElementById('detail-sujet').textContent = ticket.sujet;
        document.getElementById('detail-statut').textContent = getStatusLabel(ticket.statut);
        document.getElementById('detail-statut').className = `status-badge ${getStatusClass(ticket.statut)}`;
        document.getElementById('detail-categorie').textContent = getCategorieLabel(ticket.categorie);
        document.getElementById('detail-priorite').textContent = getPrioriteLabel(ticket.priorite);
        document.getElementById('detail-date').textContent = new Date(ticket.created_at).toLocaleString();
        document.getElementById('detail-description').textContent = ticket.description;
        
        await loadTicketMessages(ticketId);
        document.getElementById('ticket-detail-modal').style.display = 'flex';
        
    } catch (error) {
        console.error('Error loading ticket:', error);
        showToast('Erreur lors du chargement du ticket', 'error');
    }
};

const loadTicketMessages = async (ticketId) => {
    try {
        const container = document.getElementById('ticket-messages');
        container.innerHTML = '<p class="text-muted text-center">Aucun message</p>';
        
    } catch (error) {
        console.error('Error loading messages:', error);
    }
};

const sendReply = async () => {
    const message = document.getElementById('reply-message').value;
    
    if (!message.trim()) return;
    
    try {
        // Tickets endpoint not yet available
        showToast('Fonctionnalité bientôt disponible', 'info');
        document.getElementById('reply-message').value = '';
        
    } catch (error) {
        console.error('Error sending reply:', error);
        showToast('Erreur lors de l\'envoi du message', 'error');
    }
};

const initEventListeners = () => {
    document.getElementById('filter-statut').addEventListener('change', filterTickets);
    document.getElementById('btn-submit-ticket').addEventListener('click', submitNewTicket);
    document.getElementById('btn-send-reply').addEventListener('click', sendReply);
    document.getElementById('btn-logout')?.addEventListener('click', (e) => {
        e.preventDefault();
        localStorage.removeItem('exper_immo_token');
        localStorage.removeItem('exper_immo_user');
        window.location.href = '../login.html';
    });
};

// Global functions
window.openNewTicketModal = () => {
    document.getElementById('new-ticket-modal').style.display = 'flex';
};

window.closeNewTicketModal = () => {
    document.getElementById('new-ticket-modal').style.display = 'none';
};

window.openTicketDetail = (ticketId) => {
    loadTicketDetail(ticketId);
};

window.closeTicketDetailModal = () => {
    document.getElementById('ticket-detail-modal').style.display = 'none';
};

document.addEventListener('DOMContentLoaded', async () => {
    if (!initAuth()) return;
    await loadTickets();
    initEventListeners();
});
