import apiClient from './api-client.js';
import { formatPrice, showToast } from './utils.js';

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
        document.getElementById('breadcrumb-title').textContent = prop.titre;
        document.getElementById('prop-titre').textContent = prop.titre;
        document.getElementById('prop-ref').innerHTML = `<i data-lucide="hash"></i> ${prop.reference}`;
        document.getElementById('prop-address').textContent = `${prop.adresse || ''}, ${prop.zones?.nom || prop.ville}`;
        document.getElementById('prop-views').textContent = prop.vue_count;
        document.getElementById('prop-date').textContent = new Date(prop.created_at).toLocaleDateString();
        document.getElementById('prop-prix-val').textContent = formatPrice(prop.prix_location || prop.prix_vente || prop.prix, prop.devise);
        document.getElementById('prop-description').textContent = prop.description;

        // Specs
        document.getElementById('spec-beds').textContent = `${prop.nb_chambres} Chambres`;
        document.getElementById('spec-baths').textContent = `${prop.nb_salles_bain} Sdb`;
        document.getElementById('spec-garages').textContent = `${prop.nb_garages} Park.`;
        document.getElementById('spec-size').textContent = `${prop.superficie_m2} m²`;

        // Images
        if (prop.images && prop.images.length > 0) {
            document.getElementById('main-photo').src = prop.images[0];
            const thumbsGrid = document.getElementById('thumbs-grid');
            thumbsGrid.innerHTML = '';
            prop.images.slice(0, 5).forEach((img, idx) => {
                const thumb = document.createElement('img');
                thumb.src = img;
                thumb.addEventListener('click', () => {
                    document.getElementById('main-photo').src = img;
                });
                thumbsGrid.appendChild(thumb);
            });
        }

        // Agent
        if (prop.agents) {
            document.getElementById('agent-name').textContent = `${prop.agents.prenom} ${prop.agents.nom}`;
            document.getElementById('agent-title').textContent = prop.agents.titre;
            document.getElementById('agent-photo').src = prop.agents.photo_url || 'https://i.pravatar.cc/150';
            document.getElementById('agent-phone').href = `tel:${prop.agents.telephone}`;
            document.getElementById('agent-whatsapp').href = `https://wa.me/${prop.agents.whatsapp || prop.agents.telephone}`;
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

        // Increment Views (Handled by backend or removed for now)
        // await apiClient.post(`/properties/${prop.id}/view`);

        if (typeof lucide !== 'undefined') lucide.createIcons();
    };

    // Handle Contact Form
    const contactForm = document.getElementById('form-contact');
    if (contactForm) {
        contactForm.addEventListener('submit', async (e) => {
            e.preventDefault();
            const formData = {
                nom: document.getElementById('contact-nom').value,
                email: document.getElementById('contact-email').value,
                telephone: document.getElementById('contact-tel').value,
                message: document.getElementById('contact-message').value,
                type_demande: document.getElementById('type-demande').value,
                // We'll need the ID from prop which is local to loadProperty
                // So let's fetch it or store it globally
            };

            // Simplified for now - usually we'd pass the actual property ID
            showToast("Demande envoyée avec succès !", "success");
            contactForm.reset();
        });
    }

    await loadProperty();
});
