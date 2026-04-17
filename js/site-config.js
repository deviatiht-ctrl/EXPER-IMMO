/**
 * EXPERIMMO — site-config.js
 * Charge les paramètres depuis Supabase (table: parametres_site)
 * et les injecte dans tous les éléments [data-site="..."] de la page.
 *
 * Usage (dans chaque page publique):
 *   <script type="module" src="js/site-config.js"></script>
 */

import CONFIG from './config.js';

const { createClient } = supabase;
const db = createClient(CONFIG.SUPABASE_URL, CONFIG.SUPABASE_ANON_KEY);

async function loadSiteConfig() {
    try {
        const { data, error } = await db
            .from('parametres_site')
            .select('*')
            .single();

        if (error || !data) return;
        applyConfig(data);
    } catch (e) {
        console.warn('[SiteConfig] Impossible de charger les paramètres:', e.message);
    }
}

function applyConfig(cfg) {
    // ── Textes simples ──────────────────────────────────────
    setText('[data-site="name"]',        cfg.nom_entreprise);
    setText('[data-site="slogan"]',      cfg.slogan);
    setText('[data-site="address"]',     cfg.adresse);
    setText('[data-site="phone"]',       cfg.telephone);
    setText('[data-site="whatsapp"]',    cfg.whatsapp);
    setText('[data-site="email"]',       cfg.email);
    setText('[data-site="description"]', cfg.description_footer);

    // ── Liens téléphone / email ─────────────────────────────
    document.querySelectorAll('a[data-site="phone"]').forEach(a => {
        if (cfg.telephone) a.href = 'tel:' + cfg.telephone.replace(/\s/g, '');
    });
    document.querySelectorAll('a[data-site="whatsapp"]').forEach(a => {
        if (cfg.whatsapp) a.href = 'https://wa.me/' + cfg.whatsapp.replace(/[^0-9]/g, '');
    });
    document.querySelectorAll('a[data-site="email"]').forEach(a => {
        if (cfg.email) a.href = 'mailto:' + cfg.email;
    });

    // ── Réseaux sociaux (href uniquement) ───────────────────
    setHref('[data-site="facebook"]',  cfg.facebook_url);
    setHref('[data-site="instagram"]', cfg.instagram_url);
    setHref('[data-site="twitter"]',   cfg.twitter_url);
    setHref('[data-site="linkedin"]',  cfg.linkedin_url);
    setHref('[data-site="youtube"]',   cfg.youtube_url);

    // ── Copyright dynamique ─────────────────────────────────
    const year = new Date().getFullYear();
    const name = cfg.nom_entreprise || 'EXPERIMMO';
    document.querySelectorAll('[data-site="copyright"]').forEach(el => {
        el.textContent = `© ${year} ${name}. Tous droits réservés.`;
    });

    // ── Titre page (optionnel) ──────────────────────────────
    if (cfg.nom_entreprise) {
        document.title = document.title.replace(/EXPERIMMO|EXPER IMMO/g, cfg.nom_entreprise);
    }
}

function setText(selector, value) {
    if (!value) return;
    document.querySelectorAll(selector).forEach(el => {
        el.textContent = value;
    });
}

function setHref(selector, value) {
    if (!value) return;
    document.querySelectorAll(selector).forEach(el => {
        el.href = value;
    });
}

// Lancer dès que le DOM est prêt
if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', loadSiteConfig);
} else {
    loadSiteConfig();
}
