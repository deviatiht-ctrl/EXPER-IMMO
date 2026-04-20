// admin/dashboard.js
import { supabaseClient as supabase } from '../supabase-client.js';

document.addEventListener('DOMContentLoaded', async () => {
    await checkAuth();
    await Promise.all([loadStats(), loadRecentProprietaires(), loadRecentLocataires(), loadPaiementsRetard()]);
    setupLogout();
    if (typeof lucide !== 'undefined') lucide.createIcons();
});

async function checkAuth() {
    const { data: { user } } = await supabase.auth.getUser();
    if (!user) { window.location.href = '../login.html'; return; }
    const { data: profile } = await supabase.from('profiles').select('role').eq('id', user.id).single();
    if (profile?.role !== 'admin') { window.location.href = '../index.html'; }
}

async function loadStats() {
    try {
        const { data, error } = await supabase.rpc('get_admin_dashboard_stats');
        if (error) throw error;
        const s = data || {};
        setEl('stat-properties',    s.total_proprietes     ?? 0);
        setEl('stat-gestionnaires', s.total_gestionnaires  ?? 0);
        setEl('stat-owners',        s.total_proprietaires  ?? 0);
        setEl('stat-locataires',    s.total_locataires     ?? 0); // Si présent
        setEl('stat-contracts',     s.contrats_actifs      ?? 0);
        setEl('stat-revenue',       fmtNum(s.revenus_ce_mois ?? 0) + ' HTG');
        setEl('stat-retards',       s.paiements_en_retard  ?? 0);
        setEl('stat-tickets',       s.tickets_ouverts      ?? 0);
        setEl('stat-contacts',      s.nouveaux_contacts    ?? 0);
    } catch (err) {
        console.error('Stats error:', err);
    }
}

async function loadRecentProprietaires() {
    const c = document.getElementById('recent-proprietaires');
    if (!c) return;
    try {
        const { data, error } = await supabase
            .from('proprietaires')
            .select('id, est_actif, user:profiles(full_name, email, avatar_url)')
            .order('created_at', { ascending: false }).limit(5);
        if (error) throw error;
        if (!data || !data.length) {
            c.innerHTML = '<p style="text-align:center;color:#64748b;font-size:13px;padding:20px 0;">Aucun proprietaire.</p>';
            return;
        }
        c.innerHTML = data.map(p => avatarRow(p.user, p.est_actif, '#C53636')).join('');
    } catch(e) {
        console.warn('[loadRecentProprietaires]', e?.message || e);
        c.innerHTML = '<p style="text-align:center;color:#64748b;font-size:13px;padding:20px 0;">Aucun propriétaire.</p>';
    }
}

async function loadRecentLocataires() {
    const c = document.getElementById('recent-locataires');
    if (!c) return;
    try {
        const { data, error } = await supabase
            .from('locataires')
            .select('id, est_actif, user:profiles(full_name, email, avatar_url)')
            .order('created_at', { ascending: false }).limit(5);
        if (error) throw error;
        if (!data || !data.length) {
            c.innerHTML = '<p style="text-align:center;color:#64748b;font-size:13px;padding:20px 0;">Aucun locataire.</p>';
            return;
        }
        c.innerHTML = data.map(l => avatarRow(l.user, l.est_actif, '#7c3aed')).join('');
    } catch(e) {
        console.warn('[loadRecentLocataires]', e?.message || e);
        c.innerHTML = '<p style="text-align:center;color:#64748b;font-size:13px;padding:20px 0;">Aucun locataire.</p>';
    }
}

async function loadPaiementsRetard() {
    const c = document.getElementById('paiements-retard');
    if (!c) return;
    try {
        const { data, error } = await supabase
            .from('paiements')
            .select('id, montant_total, jours_retard, locataire:locataires(user:profiles(full_name)), propriete:proprietes(titre)')
            .eq('statut', 'en_retard').order('jours_retard', { ascending: false }).limit(5);
        if (error) throw error;
        if (!data || !data.length) {
            c.innerHTML = '<p style="color:#10b981;font-size:13px;padding:10px 0;font-weight:600;">Aucun paiement en retard</p>';
            return;
        }
        c.innerHTML = data.map(p =>
            '<div class="activity-item">' +
            '<div class="activity-icon" style="background:#fee2e2;color:#dc2626;"><i data-lucide="clock"></i></div>' +
            '<div class="activity-content">' +
            '<h4>' + fmtNum(p.montant_total || 0) + ' HTG — ' + esc(p.locataire?.user?.full_name || 'N/A') + '</h4>' +
            '<p>' + esc(p.propriete?.titre || 'N/A') + '</p>' +
            '</div>' +
            '<span class="activity-time" style="color:#dc2626;font-weight:600;">' + (p.jours_retard || 0) + 'j</span>' +
            '</div>'
        ).join('');
        if (typeof lucide !== 'undefined') lucide.createIcons();
    } catch(e) {
        console.warn('[loadPaiementsRetard]', e?.message || e);
        c.innerHTML = '<p style="color:#10b981;font-size:13px;padding:10px 0;font-weight:600;">Aucun paiement en retard</p>';
    }
}

function setupLogout() {
    const btn = document.getElementById('btn-logout');
    if (btn) btn.addEventListener('click', async () => { await supabase.auth.signOut(); window.location.href = '../login.html'; });
}

function avatarRow(u, isActive, color) {
    u = u || {};
    const name = u.full_name || 'Inconnu';
    const ini = name.split(' ').map(function(n){ return n[0]; }).join('').substring(0,2).toUpperCase();
    const av = u.avatar_url
        ? '<img src="' + esc(u.avatar_url) + '" style="width:38px;height:38px;border-radius:10px;object-fit:cover;">'
        : '<div style="width:38px;height:38px;border-radius:10px;background:' + color + ';color:white;display:flex;align-items:center;justify-content:center;font-weight:700;font-size:13px;flex-shrink:0;">' + ini + '</div>';
    const badge = isActive !== false ? '<span class="status-badge actif">Actif</span>' : '<span class="status-badge inactive">Inactif</span>';
    return '<div class="activity-item"><div class="table-user">' + av + '<div class="table-user-info"><h4>' + esc(name) + '</h4><p>' + esc(u.email || '') + '</p></div></div>' + badge + '</div>';
}

function setEl(id, v) { var el = document.getElementById(id); if (el) el.textContent = v; }
function fmtNum(n) { return Number(n).toLocaleString('fr-FR'); }
function esc(s) { return String(s || '').replace(/&/g,'&amp;').replace(/</g,'&lt;').replace(/>/g,'&gt;'); }