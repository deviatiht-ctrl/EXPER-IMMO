import apiClient from './api-client.js';
import { formatPrice, showToast } from './utils.js';

const API_URL = window.EXPER_API_URL || 'https://exper-immo.onrender.com';

function fixImgUrl(url) {
    if (!url) return null;
    if (url.startsWith('/static/')) return API_URL + url;
    return url;
}

function setEl(id, val) {
    const el = document.getElementById(id);
    if (el) el.textContent = val ?? '';
}

document.addEventListener('DOMContentLoaded', async () => {
    const urlParams = new URLSearchParams(window.location.search);
    const slug = urlParams.get('slug');

    if (!slug) {
        window.location.href = 'index.html';
        return;
    }

    const loadProperty = async () => {
        try {
            const prop = await apiClient.get(`/properties/${slug}`);

            if (!prop) {
                showToast("Propriété introuvable.", "error");
                return;
            }

            // Update UI
            document.title = `${prop.titre} | EXPER IMMO`;
            setEl('breadcrumb-title', prop.titre);
            setEl('prop-titre', prop.titre);
            const refEl = document.getElementById('prop-ref');
            if (refEl) refEl.innerHTML = `<i data-lucide="hash"></i> ${prop.reference || ''}`;
            setEl('prop-address', [prop.adresse, prop.ville].filter(Boolean).join(', '));
            setEl('prop-date', prop.created_at ? new Date(prop.created_at).toLocaleDateString('fr-FR') : '');
            const prixEl = document.getElementById('prop-prix-val');
            if (prixEl) prixEl.textContent = formatPrice(prop.prix, prop.devise);
            setEl('prop-description', prop.description || '');

            // Specs
            setEl('spec-beds', prop.nb_chambres != null ? `${prop.nb_chambres} Chambres` : '-');
            setEl('spec-baths', prop.nb_salles_bain != null ? `${prop.nb_salles_bain} Sdb` : '-');
            setEl('spec-garages', prop.nb_garages != null ? `${prop.nb_garages} Park.` : '-');
            setEl('spec-size', prop.superficie_m2 ? `${prop.superficie_m2} m²` : '-');

            // Images
            const images = (prop.images || []).map(fixImgUrl).filter(Boolean);
            if (images.length > 0) {
                const mainPhoto = document.getElementById('main-photo');
                if (mainPhoto) mainPhoto.src = images[0];
                const thumbsGrid = document.getElementById('thumbs-grid');
                if (thumbsGrid) {
                    thumbsGrid.innerHTML = '';
                    images.slice(0, 5).forEach(img => {
                        const thumb = document.createElement('img');
                        thumb.src = img;
                        thumb.style.cssText = 'cursor:pointer;object-fit:cover;border-radius:8px;';
                        thumb.addEventListener('click', () => {
                            if (mainPhoto) mainPhoto.src = img;
                        });
                        thumbsGrid.appendChild(thumb);
                    });
                }
            }

            // Agent
            if (prop.agents) {
                setEl('agent-name', `${prop.agents.prenom || ''} ${prop.agents.nom || ''}`.trim());
                setEl('agent-title', prop.agents.titre || '');
                const agentPhoto = document.getElementById('agent-photo');
                if (agentPhoto) agentPhoto.src = prop.agents.photo_url || 'https://i.pravatar.cc/150';
                const agentPhone = document.getElementById('agent-phone');
                if (agentPhone) agentPhone.href = `tel:${prop.agents.telephone || ''}`;
                const agentWa = document.getElementById('agent-whatsapp');
                if (agentWa) agentWa.href = `https://wa.me/${prop.agents.whatsapp || prop.agents.telephone || ''}`;
            }

            // Amenagements
            const amenGrid = document.getElementById('amenagements-grid');
            if (amenGrid) {
                amenGrid.innerHTML = '';
                (prop.amenagements || prop.amenities || []).forEach(am => {
                    const item = document.createElement('div');
                    item.className = 'amenagement on';
                    item.innerHTML = `<i data-lucide="check-circle"></i> ${am}`;
                    amenGrid.appendChild(item);
                });
            }

            if (typeof lucide !== 'undefined') lucide.createIcons();

        } catch (err) {
            console.error('loadProperty:', err);
            showToast('Erreur lors du chargement de la propriété', 'error');
        }
    };

    // Handle Contact Form
    const contactForm = document.getElementById('form-contact');
    if (contactForm) {
        contactForm.addEventListener('submit', async (e) => {
            e.preventDefault();
            showToast("Demande envoyée avec succès !", "success");
            contactForm.reset();
        });
    }

    await loadProperty();
});
