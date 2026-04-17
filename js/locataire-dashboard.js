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

    const { data: loc } = await supabaseClient
        .from('locataires')
        .select('*')
        .eq('user_id', user.id)
        .single();
    
    if (loc) {
        locataireId = loc.id_locataire;
        document.getElementById('user-name').textContent = `${loc.prenom} ${loc.nom}`;
    }

    const lastLogin = new Date(user.last_sign_in_at).toLocaleString('fr-FR');
    document.getElementById('last-login').textContent = lastLogin;
    document.getElementById('welcome-title').textContent = `Bonjour, ${loc?.prenom || 'M.'}`;
};

const loadDashboardData = async () => {
    if (!locataireId) return;

    // Load Bien & Contrat
    const { data: contrat } = await supabaseClient
        .from('contrats')
        .select('*, proprietes(titre)')
        .eq('locataire_id', locataireId)
        .eq('statut', 'actif')
        .single();

    if (contrat) {
        document.getElementById('stat-bien-occupe').textContent = contrat.proprietes?.titre || 'Oui';
        document.getElementById('stat-contrat-statut').textContent = 'Actif';
    }

    // Load Factures
    const { data: factures } = await supabaseClient
        .from('factures')
        .select('*')
        .eq('id_locataire', locataireId)
        .order('date_emission', { ascending: false })
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
