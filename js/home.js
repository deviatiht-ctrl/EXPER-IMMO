// home.js
import { supabaseClient } from './supabase-client.js';
import { formatPrice } from './utils.js';

document.addEventListener('DOMContentLoaded', async () => {
    const featuredGrid = document.getElementById('featured-grid');
    const searchTabs = document.querySelectorAll('.search-tabs .tab');

    // Handle Tab Switching
    searchTabs.forEach(tab => {
        tab.addEventListener('click', () => {
            searchTabs.forEach(t => t.classList.remove('active'));
            tab.classList.add('active');
            // Logic to update search context if needed
        });
    });

    // Load Zones for Search
    const loadZones = async () => {
        const { data: zones, error } = await supabaseClient
            .from('zones')
            .select('*')
            .eq('actif', true)
            .order('ordre', { ascending: true });

        if (error) {
            console.error('Error loading zones:', error);
            return;
        }

        const zoneSelect = document.getElementById('zone');
        if (zoneSelect) {
            zones.forEach(zone => {
                const option = document.createElement('option');
                option.value = zone.id;
                option.textContent = zone.nom;
                zoneSelect.appendChild(option);
            });
        }
    };

    // Load Featured Properties
    const loadFeaturedProperties = async () => {
        const { data: props, error } = await supabaseClient
            .from('proprietes')
            .select(`
                *,
                zones (nom),
                agents (prenom, nom, photo_url)
            `)
            .eq('est_vedette', true)
            .eq('est_actif', true)
            .limit(3);

        if (error) {
            console.error('Error loading featured properties:', error);
            featuredGrid.innerHTML = '<p class="text-center">Erreur lors du chargement des propriétés.</p>';
            return;
        }

        if (props.length === 0) {
            featuredGrid.innerHTML = '<p class="text-center">Aucune propriété vedette pour le moment.</p>';
            return;
        }

        featuredGrid.innerHTML = '';
        props.forEach(prop => {
                const card = createPropertyCard(prop);
                featuredGrid.appendChild(card);
        });

        if (typeof lucide !== 'undefined') lucide.createIcons();
    };

    const createPropertyCard = (prop) => {
        const div = document.createElement('div');
        div.className = 'prop-card card fade-in';
        
        const mainImg = prop.images && prop.images.length > 0 
            ? prop.images[0] 
            : 'https://images.unsplash.com/photo-1564013799919-ab600027ffc6?auto=format&fit=crop&q=80&w=800';

        div.innerHTML = `
            <div class="prop-img-wrap">
                <img src="${mainImg}" alt="${prop.titre}" loading="lazy">
                <div class="prop-badge-group">
                    <span class="badge-statut badge-${prop.type_transaction}">
                        <i data-lucide="tag"></i> ${prop.type_transaction === 'vente' ? 'À Vendre' : 'À Louer'}
                    </span>
                    ${prop.est_vedette ? '<span class="badge-vedette badge"><i data-lucide="star"></i> Vedette</span>' : ''}
                </div>
                <button class="btn-favori" data-id="${prop.id}">
                    <i data-lucide="heart"></i>
                </button>
            </div>
            <div class="prop-info">
                <div class="prop-prix">
                    ${formatPrice(prop.prix_location || prop.prix_vente || prop.prix, prop.devise)}
                </div>
                <h3 class="prop-title">${prop.titre}</h3>
                <p class="prop-location">
                    <i data-lucide="map-pin"></i>
                    ${prop.zones?.nom || prop.ville || ''}
                </p>
                <div class="prop-specs">
                    <span><i data-lucide="bed"></i> ${prop.nb_chambres} ch.</span>
                    <span><i data-lucide="bath"></i> ${prop.nb_salles_bain} sdb</span>
                    <span><i data-lucide="maximize"></i> ${prop.superficie_m2 || 0} m²</span>
                </div>
                <a href="propriete.html?slug=${prop.slug}" class="btn-voir">
                    Détails <i data-lucide="arrow-right"></i>
                </a>
            </div>
        `;
        return div;
    };

    await loadZones();
    await loadFeaturedProperties();
});
