// agents.js
import { apiClient } from './api-client.js';

document.addEventListener('DOMContentLoaded', async () => {
    const agentsGrid = document.getElementById('agents-grid');

    const loadAgents = async () => {
        const agents = await apiClient.get('/agents').catch(() => null);

        if (!agents) {
            agentsGrid.innerHTML = '<p>Erreur lors du chargement des agents.</p>';
            return;
        }

        agentsGrid.innerHTML = '';
        agents.forEach(agent => {
            const card = document.createElement('div');
            card.className = 'agent-card card fade-in';
            card.innerHTML = `
                <div class="agent-img-wrap">
                    <img src="${agent.photo_url || 'https://i.pravatar.cc/150?u=' + agent.id}" alt="${agent.prenom}">
                </div>
                <h3>${agent.prenom} ${agent.nom}</h3>
                <span class="agent-title">${agent.titre}</span>
                <p class="mb-2" style="font-size: 14px; color: var(--text-secondary)">
                    ${(agent.specialites || []).slice(0, 3).join(' · ') || '&nbsp;'}
                </p>
                <div class="agent-stats-row">
                    <span><i data-lucide="award"></i> ${agent.experience_ans || 0} ans</span>
                    <span><i data-lucide="check-circle"></i> ${(agent.nb_ventes || 0) + (agent.nb_locations || 0)} deals</span>
                </div>
                <div class="agent-contact-btns">
                    <a href="tel:${agent.telephone}" class="btn-outline w-full"><i data-lucide="phone"></i></a>
                    <a href="https://wa.me/${agent.whatsapp || agent.telephone}" class="btn-success btn w-full" style="background:#25D366;color:white;border:none">
                        <i data-lucide="message-circle"></i>
                    </a>
                </div>
            `;
            agentsGrid.appendChild(card);
        });

        if (typeof lucide !== 'undefined') lucide.createIcons();
    };

    await loadAgents();
});
