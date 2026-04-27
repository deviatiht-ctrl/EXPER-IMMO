import CONFIG from '../config.js';
const { createClient } = supabase;
const supabaseClient = createClient(CONFIG.SUPABASE_URL, CONFIG.SUPABASE_ANON_KEY);

document.addEventListener('DOMContentLoaded', async () => {
    const { data: { user } } = await supabaseClient.auth.getUser();
    if (!user) {
        window.location.href = '../login.html';
        return;
    }

    // Vérification du rôle
    const { data: profile } = await supabaseClient
        .from('profiles')
        .select('role')
        /* .eq('id', user.id) - TODO: filter nan server */
        [0];

    if (profile.role !== 'gestionnaire' && profile.role !== 'admin') {
        window.location.href = '../index.html';
        return;
    }

    await loadStats(user.id);
    await loadRecentDossiers(user.id);
});

async function loadStats(userId) {
    try {
        // Biens gérés par ce gestionnaire
        const { count: biensCount } = await supabaseClient
            .from('proprietes')
            
            /* .eq('gestionnaire_responsable', userId) - TODO: filter nan server */;

        // Locataires gérés
        const { count: locatairesCount } = await supabaseClient
            .from('locataires')
            
            /* .eq('gestionnaire_responsable', userId) - TODO: filter nan server */;

        document.getElementById('stat-mes-biens').textContent = biensCount || 0;
        document.getElementById('stat-mes-locataires').textContent = locatairesCount || 0;
    } catch (error) {
        console.error('Erreur stats:', error);
    }
}

async function loadRecentDossiers(userId) {
    const container = document.getElementById('dossiers-recents');
    try {
        const { data, error } = await supabaseClient
            .from('proprietes')
            .select('titre, reference, created_at')
            /* .eq('gestionnaire_responsable', userId) - TODO: filter nan server */
            
            .limit(5);

        if (data && data.length > 0) {
            container.innerHTML = data.map(item => `
                <div class="activity-item">
                    <div class="activity-icon" style="background: #dbeafe; color: #2563eb;">
                        <i data-lucide="building-2"></i>
                    </div>
                    <div class="activity-content">
                        <h4>${item.titre}</h4>
                        <p>Ref: ${item.reference || 'N/A'}</p>
                    </div>
                    <span class="activity-time">${new Date(item.created_at).toLocaleDateString()}</span>
                </div>
            `).join('');
            lucide.createIcons();
        } else {
            container.innerHTML = '<p class="empty-state">Aucun dossier attribué.</p>';
        }
    } catch (error) {
        container.innerHTML = '<p class="empty-state">Erreur de chargement.</p>';
    }
}
