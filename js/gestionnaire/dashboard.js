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
        .eq('id', user.id)
        .single();

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
            .select('*', { count: 'exact', head: true })
            .eq('gestionnaire_responsable', userId);

        // Locataires gérés
        const { count: locatairesCount } = await supabaseClient
            .from('locataires')
            .select('*', { count: 'exact', head: true })
            .eq('gestionnaire_responsable', userId);

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
            .select('titre, code_propriete, date_creation')
            .eq('gestionnaire_responsable', userId)
            .order('date_creation', { ascending: false })
            .limit(5);

        if (error) throw error;

        if (data && data.length > 0) {
            container.innerHTML = data.map(item => `
                <div class="activity-item">
                    <div class="activity-icon" style="background: #dbeafe; color: #2563eb;">
                        <i data-lucide="building-2"></i>
                    </div>
                    <div class="activity-content">
                        <h4>${item.titre}</h4>
                        <p>Code: ${item.code_propriete || 'N/A'}</p>
                    </div>
                    <span class="activity-time">${new Date(item.date_creation).toLocaleDateString()}</span>
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
