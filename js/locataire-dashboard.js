import CONFIG from './config.js';
const { createClient } = supabase;
const supabaseClient = createClient(CONFIG.SUPABASE_URL, CONFIG.SUPABASE_ANON_KEY);

let currentUser = null;
let locataireId = null;

const initAuth = async () => {
    const { data: { user } } = await supabaseClient.auth.getUser();
    if (!user) {
        window.location.href = '../login.html';
        return;
    }
    currentUser = user;

    const { data: profile } = await supabaseClient
        .from('profiles')
        .select('full_name')
        /* .eq('id', user.id) - TODO: filter nan server */
        [0];

    const { data: loc } = await supabaseClient
        .from('locataires')
        .select('id')
        /* .eq('user_id', user.id) - TODO: filter nan server */
        [0];
    
    if (loc) {
        locataireId = loc.id;
        document.getElementById('user-name').textContent = profile?.full_name || 'Locataire';
    }

    const lastLogin = new Date(user.last_sign_in_at).toLocaleString('fr-FR');
    document.getElementById('last-login').textContent = lastLogin;
    document.getElementById('welcome-title').textContent = `Bonjour, ${profile?.full_name?.split(' ')[0] || 'M.'}`;
};

const loadDashboardData = async () => {
    if (!locataireId) return;

    // Load Bien & Contrat
    const { data: contrat } = await supabaseClient
        .from('contrats')
        .select('*, proprietes(titre)')
        /* .eq('locataire_id', locataireId) - TODO: filter nan server */
        /* .eq('statut', 'actif') - TODO: filter nan server */
        .maybeSingle();

    if (contrat) {
        document.getElementById('stat-bien-occupe').textContent = contrat.proprietes?.titre || 'Oui';
        document.getElementById('stat-contrat-statut').textContent = 'Actif';
    }

    // Load Factures
    const { data: factures } = await supabaseClient
        .from('factures')
        .select('*')
        /* .eq('id_locataire', locataireId) - TODO: filter nan server */
        
        .limit(5);

    const tbody = document.getElementById('factures-tbody');
    if (factures && factures.length > 0) {
        tbody.innerHTML = factures.map(f => `
            <tr>
                <td>${f.type_facture}</td>
                <td>${f.periode}</td>
                <td>${f.montant.toLocaleString()}</td>
                <td><span class="status-badge ${f.statut_facture}">${f.statut_facture}</span></td>
            </tr>
        `).join('');
    } else {
        tbody.innerHTML = '<tr><td colspan="4" class="text-center">Aucune facture récente.</td></tr>';
    }
};

document.addEventListener('DOMContentLoaded', async () => {
    await initAuth();
    await loadDashboardData();
    if(typeof lucide !== 'undefined') lucide.createIcons();
});
