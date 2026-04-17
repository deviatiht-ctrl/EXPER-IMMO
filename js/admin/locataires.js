import { supabaseClient as supabase } from '../supabase-client.js';

let locataires = [];
let currentLocataire = null;

document.addEventListener('DOMContentLoaded', async () => {
    await checkAuth();
    await Promise.all([loadLocataires(), loadStats()]);
    setupEventListeners();
    if (typeof lucide !== 'undefined') lucide.createIcons();
});

async function checkAuth() {
    const { data: { user } } = await supabase.auth.getUser();
    if (!user) { window.location.href = '../login.html'; return; }
    const { data: profile } = await supabase.from('profiles').select('role').eq('id', user.id).single();
    if (profile?.role !== 'admin') { window.location.href = '../index.html'; }
}

async function loadLocataires() {
    try {
        const { data, error } = await supabase
            .from('locataires')
            .select('*, user:profiles(full_name, email, phone, avatar_url, adresse, ville, date_naissance)')
            .order('created_at', { ascending: false });
        if (error) throw error;
        locataires = data || [];
        renderLocatairesTable();
    } catch (err) {
        console.error('loadLocataires:', err);
        showToast('Erreur de chargement des locataires', 'error');
    }
}

async function loadStats() {
    try {
        const [{ count: total }, { count: actifs }, { count: contrats }, { count: retards }] = await Promise.all([
            supabase.from('locataires').select('*', { count: 'exact', head: true }),
            supabase.from('locataires').select('*', { count: 'exact', head: true }).eq('est_actif', true),
            supabase.from('contrats').select('*', { count: 'exact', head: true }).eq('statut', 'actif'),
            supabase.from('paiements').select('*', { count: 'exact', head: true }).eq('statut', 'en_retard'),
        ]);
        setEl('stat-total-loc', total || 0);
        setEl('stat-actifs-loc', actifs || 0);
        setEl('stat-contrats-loc', contrats || 0);
        setEl('stat-retards-loc', retards || 0);
    } catch (err) { console.error('loadStats:', err); }
}

function renderLocatairesTable() {
    const tbody = document.getElementById('locataires-table');
    if (!tbody) return;
    if (!locataires.length) {
        tbody.innerHTML = '<tr><td colspan="6" style="text-align:center;padding:50px;color:#64748b;">Aucun locataire trouvé</td></tr>';
        return;
    }
    tbody.innerHTML = locataires.map(l => {
        const u = l.user || {};
        const name = u.full_name || 'N/A';
        const av = u.avatar_url
            ? '<img src="' + esc(u.avatar_url) + '" style="width:38px;height:38px;border-radius:10px;object-fit:cover;">'
            : '<div style="width:38px;height:38px;border-radius:10px;background:#7c3aed;color:white;display:flex;align-items:center;justify-content:center;font-weight:700;font-size:13px;flex-shrink:0;">' + name.split(' ').map(function(n){return n[0]||'';}).join('').substring(0,2).toUpperCase() + '</div>';
        const actif = l.est_actif !== false;
        return '<tr data-id="' + l.id_locataire + '">' +
            '<td><div class="table-user">' + av + '<div class="table-user-info"><h4>' + esc(name) + '</h4><p>' + esc(u.email || '') + '</p></div></div></td>' +
            '<td>' + esc(u.phone || 'N/A') + '</td>' +
            '<td>' + esc(l.profession || 'N/A') + '</td>' +
            '<td>' + (l.revenu_mensuel ? '$' + Number(l.revenu_mensuel).toLocaleString('fr-FR') : 'N/A') + '</td>' +
            '<td><span class="status-badge ' + (actif ? 'actif' : 'inactive') + '">' + (actif ? 'Actif' : 'Inactif') + '</span></td>' +
            '<td><div class="action-btns">' +
            '<button class="action-btn view" onclick="viewLocataire(\'' + l.id_locataire + '\')" title="Voir"><i data-lucide="eye"></i></button>' +
            '<button class="action-btn edit" onclick="editLocataire(\'' + l.id_locataire + '\')" title="Modifier"><i data-lucide="edit-2"></i></button>' +
            '<button class="action-btn delete" onclick="deleteLocataire(\'' + l.id_locataire + '\')" title="Supprimer"><i data-lucide="trash-2"></i></button>' +
            '</div></td></tr>';
    }).join('');
    if (typeof lucide !== 'undefined') lucide.createIcons();
}

window.openModal = function(id) {
    const m = document.getElementById(id);
    if (m) { m.classList.add('is-open'); document.body.style.overflow = 'hidden'; }
};

window.closeModal = function(id) {
    const m = document.getElementById(id);
    if (m) { m.classList.remove('is-open'); document.body.style.overflow = ''; }
    currentLocataire = null;
    const form = document.getElementById('locataire-form');
    if (form) form.reset();
    setEl('loc-modal-title', 'Nouveau Locataire');
};

window.viewLocataire = async function(id) {
    const l = locataires.find(function(x){ return x.id_locataire === id; });
    if (!l) return;
    const u = l.user || {};
    const { data: contracts } = await supabase
        .from('contrats')
        .select('reference, date_debut, date_fin, loyer_mensuel, statut, propriete:proprietes(titre)')
        .eq('locataire_id', id)
        .order('date_debut', { ascending: false });
    const { data: payments } = await supabase
        .from('paiements')
        .select('reference, montant_total, date_echeance, statut')
        .eq('locataire_id', id)
        .order('date_echeance', { ascending: false })
        .limit(5);
    const contractRows = (contracts || []).map(function(c){
        return '<div class="detail-card"><div class="detail-card-title">' + esc(c.reference || '') + ' â€” ' + esc(c.propriete?.titre || 'N/A') + '</div><div class="detail-card-sub">$' + Number(c.loyer_mensuel||0).toLocaleString('fr-FR') + '/mois Â· ' + esc(c.statut) + ' Â· ' + (c.date_debut||'').substring(0,10) + ' â†’ ' + (c.date_fin||'').substring(0,10) + '</div></div>';
    }).join('') || '<p style="color:#64748b;font-size:13px;">Aucun contrat</p>';
    const payRows = (payments || []).map(function(p){
        return '<div class="detail-row"><strong>' + (p.date_echeance||'').substring(0,10) + '</strong><span>$' + Number(p.montant_total||0).toLocaleString('fr-FR') + ' â€” <span class="status-badge ' + esc(p.statut) + '">' + esc(p.statut) + '</span></span></div>';
    }).join('') || '<p style="color:#64748b;font-size:13px;">Aucun paiement</p>';
    showModal('DÃ©tails â€” ' + esc(u.full_name || 'Locataire'), `
        <div class="detail-section"><h4>Informations Personnelles</h4>
            <div class="detail-row"><strong>Email</strong><span>${esc(u.email||'N/A')}</span></div>
            <div class="detail-row"><strong>TÃ©lÃ©phone</strong><span>${esc(u.phone||'N/A')}</span></div>
            <div class="detail-row"><strong>Adresse</strong><span>${esc((u.adresse||'') + ' ' + (u.ville||''))}</span></div>
            <div class="detail-row"><strong>Profession</strong><span>${esc(l.profession||'N/A')}</span></div>
            <div class="detail-row"><strong>Employeur</strong><span>${esc(l.employeur||'N/A')}</span></div>
            <div class="detail-row"><strong>Revenu mensuel</strong><span>${l.revenu_mensuel ? '$'+Number(l.revenu_mensuel).toLocaleString('fr-FR') : 'N/A'}</span></div>
            <div class="detail-row"><strong>Contact urgence</strong><span>${esc(l.contact_urgence_nom||'N/A')} ${esc(l.contact_urgence_phone||'')}</span></div>
        </div>
        <div class="detail-section"><h4>Contrats (${(contracts||[]).length})</h4>${contractRows}</div>
        <div class="detail-section"><h4>Derniers Paiements</h4>${payRows}</div>
    `);
};

window.editLocataire = function(id) {
    const l = locataires.find(function(x){ return x.id_locataire === id; });
    if (!l) return;
    currentLocataire = l;
    const u = l.user || {};
    setEl('loc-modal-title', 'Modifier le Locataire');
    setVal('loc-nom', u.full_name || '');
    setVal('loc-email', u.email || '');
    setVal('loc-phone', u.phone || '');
    setVal('loc-ddn', u.date_naissance || '');
    setVal('loc-adresse', u.adresse || '');
    setVal('loc-ville', u.ville || '');
    setVal('loc-profession', l.profession || '');
    setVal('loc-employeur', l.employeur || '');
    setVal('loc-revenu', l.revenu_mensuel || '');
    setVal('loc-nb-personnes', l.nb_personnes || '');
    setVal('loc-contact-nom', l.contact_urgence_nom || '');
    setVal('loc-contact-phone', l.contact_urgence_phone || '');
    setVal('loc-contact-relation', l.contact_urgence_relation || '');
    openModal('add-locataire');
    if (typeof lucide !== 'undefined') lucide.createIcons();
};

window.saveLocataire = async function(e) {
    e.preventDefault();
    const btn = document.getElementById('loc-save-btn');
    if (btn) { btn.disabled = true; btn.innerHTML = '<span class="spinner-small"></span> Enregistrement...'; }
    try {
        const locData = {
            profession: getVal('loc-profession'),
            employeur: getVal('loc-employeur'),
            revenu_mensuel: parseFloat(getVal('loc-revenu')) || null,
            nb_personnes: parseInt(getVal('loc-nb-personnes')) || null,
            contact_urgence_nom: getVal('loc-contact-nom'),
            contact_urgence_phone: getVal('loc-contact-phone'),
            contact_urgence_relation: getVal('loc-contact-relation'),
        };
        const profileData = {
            full_name: getVal('loc-nom'),
            phone: getVal('loc-phone'),
            adresse: getVal('loc-adresse'),
            ville: getVal('loc-ville'),
            date_naissance: getVal('loc-ddn') || null,
        };
        if (currentLocataire) {
            const { error: pe } = await supabase.from('profiles').update(profileData).eq('id', currentLocataire.user_id);
            if (pe) throw pe;
            const { error: le } = await supabase.from('locataires').update(locData).eq('id_locataire', currentLocataire.id_locataire);
            if (le) throw le;
            showToast('Locataire mis à jour', 'success');
        } else {
            const pwd = genPwd();
            const { data: auth, error: ae } = await supabase.auth.signUp({
                email: getVal('loc-email'),
                password: pwd,
                options: { data: { full_name: getVal('loc-nom'), role: 'locataire' } }
            });
            if (ae) throw ae;
            if (!auth.user) throw new Error('Compte déjà existant ou confirmation email requise.');
            const uid = auth.user.id;
            // Wait for on_auth_user_created trigger
            await new Promise(r => setTimeout(r, 1200));
            const { error: pe } = await supabase.from('profiles').upsert(
                { id: uid, ...profileData, role: 'locataire' },
                { onConflict: 'id' }
            );
            if (pe) throw pe;
            const { error: le } = await supabase.from('locataires').insert([{ user_id: uid, ...locData }]);
            if (le) throw le;
            showToast('Locataire créé! Mot de passe: ' + pwd, 'success');
        }
        closeModal('add-locataire');
        await Promise.all([loadLocataires(), loadStats()]);
    } catch (err) {
        console.error('saveLocataire:', err);
        showToast(err.message || 'Erreur lors de l\'enregistrement', 'error');
    } finally {
        if (btn) { btn.disabled = false; btn.innerHTML = '<i data-lucide="save"></i><span>Enregistrer</span>'; if (typeof lucide!=='undefined') lucide.createIcons(); }
    }
};

window.deleteLocataire = async function(id) {
    if (!confirm('Supprimer ce locataire ?')) return;
    try {
        const { error } = await supabase.from('locataires').delete().eq('id_locataire', id);
        if (error) throw error;
        showToast('Locataire supprimÃ©', 'success');
        await Promise.all([loadLocataires(), loadStats()]);
    } catch (err) { showToast(err.message || 'Erreur de suppression', 'error'); }
};

function setupEventListeners() {
    document.getElementById('btn-logout')?.addEventListener('click', async () => {
        await supabase.auth.signOut();
        window.location.href = '../login.html';
    });
    document.getElementById('search-locataires')?.addEventListener('input', function(e) {
        const q = e.target.value.toLowerCase();
        document.querySelectorAll('#locataires-table tr').forEach(function(r) {
            r.style.display = r.textContent.toLowerCase().includes(q) ? '' : 'none';
        });
    });
    document.querySelectorAll('.modal').forEach(function(m) {
        m.addEventListener('click', function(e) { if (e.target === m) m.classList.remove('is-open'); });
    });
}

function showToast(msg, type) {
    type = type || 'info';
    var t = document.createElement('div');
    t.className = 'toast toast-' + type;
    t.innerHTML = '<i data-lucide="' + (type==='success'?'check-circle':type==='error'?'alert-circle':'info') + '"></i><span>' + esc(msg) + '</span>';
    document.body.appendChild(t);
    if (typeof lucide !== 'undefined') lucide.createIcons();
    setTimeout(function(){ t.remove(); }, 5000);
}

function showModal(title, content) {
    var m = document.createElement('div');
    m.className = 'modal is-open';
    m.innerHTML = '<div class="modal-content modal-lg"><div class="modal-header"><h3>' + title + '</h3><button class="modal-close" onclick="this.closest(\'.modal\').remove()"><i data-lucide="x"></i></button></div><div class="modal-body">' + content + '</div></div>';
    document.body.appendChild(m);
    if (typeof lucide !== 'undefined') lucide.createIcons();
}

function setEl(id, v) { var e = document.getElementById(id); if (e) e.textContent = v; }
function setVal(id, v) { var e = document.getElementById(id); if (e) e.value = v; }
function getVal(id) { var e = document.getElementById(id); return e ? e.value.trim() : ''; }
function esc(s) { return String(s||'').replace(/&/g,'&amp;').replace(/</g,'&lt;').replace(/>/g,'&gt;'); }
function genPwd() { var c='ABCDEFGHJKLMNPQRSTUVWXYZabcdefghjkmnpqrstuvwxyz23456789!@#'; var p=''; for(var i=0;i<12;i++) p+=c[Math.floor(Math.random()*c.length)]; return p; }