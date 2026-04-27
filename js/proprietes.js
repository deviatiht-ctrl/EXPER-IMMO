import apiClient from './api-client.js';
import { formatPrice } from './utils.js';

document.addEventListener('DOMContentLoaded', async () => {
    const catalogGrid = document.getElementById('catalog-grid');
    const nbResultats = document.getElementById('nb-resultats');
    const emptyState = document.getElementById('empty-state');
    const btnApplyFilters = document.getElementById('btn-apply-filters');

    // State
    const filters = {
        transaction: 'all',
        types: [],
        prix_min: null,
        prix_max: null,
        chambres: 0,
        meuble: false,
        tri: 'recent',
        page: 0
    };

    // Load URL params
    const urlParams = new URLSearchParams(window.location.search);
    if (urlParams.get('type')) filters.transaction = urlParams.get('type');
    if (urlParams.get('type_p')) filters.types = [urlParams.get('type_p')];
    if (urlParams.get('p_max')) filters.prix_max = parseInt(urlParams.get('p_max'));

    // Init UI from state
    const syncUI = () => {
        // Transaction
        document.querySelectorAll('#filter-transaction .toggle').forEach(btn => {
            btn.classList.toggle('active', btn.dataset.val === filters.transaction);
        });
        // Types
        document.querySelectorAll('#filter-types input').forEach(cb => {
            cb.checked = filters.types.includes(cb.value);
        });
        // Prix
        document.getElementById('prix-max-sidebar').value = filters.prix_max || '';
    };

    const loadProperties = async () => {
        catalogGrid.innerHTML = '<div class="skeleton-card" style="height:320px;border-radius:16px;background:#f1f5f9;animation:pulse 1.4s ease-in-out infinite;"></div>'.repeat(6);
        emptyState.style.display = 'none';
        nbResultats.textContent = 'Chargement...';

        try {
            // Build query params
            const params = new URLSearchParams();
            if (filters.transaction !== 'all') params.append('type_transaction', filters.transaction);
            if (filters.types.length > 0) params.append('type_bien', filters.types[0]); // Simple filter for now
            
            const properties = await apiClient.get(`/properties?${params.toString()}`);

            if (!properties || properties.length === 0) {
                catalogGrid.innerHTML = '';
                emptyState.style.display = 'block';
                nbResultats.textContent = '0 propriété';
                return;
            }

            catalogGrid.innerHTML = '';
            properties.forEach(prop => {
                const card = createPropertyCard(prop);
                catalogGrid.appendChild(card);
            });

            nbResultats.innerHTML = `<strong>${properties.length}</strong> propriété(s) trouvée(s)`;
            lucide.createIcons();
        } catch (error) {
            console.error('Erreur chargement propriétés:', error);
            catalogGrid.innerHTML = '';
            nbResultats.textContent = 'Erreur de chargement';
            emptyState.style.display = 'block';
        }
    };

    const API_URL = window.EXPER_API_URL || 'https://exper-immo.onrender.com';
    const fixImg = (url) => url && url.startsWith('/static/') ? API_URL + url : url;

    const createPropertyCard = (prop) => {
        const div = document.createElement('div');
        div.className = 'prop-card card fade-in';
        const rawImg = prop.images && prop.images.length > 0 ? prop.images[0] : null;
        const mainImg = fixImg(rawImg) || 'https://images.unsplash.com/photo-1564013799919-ab600027ffc6?auto=format&fit=crop&q=80&w=800';

        div.innerHTML = `
            <div class="prop-img-wrap">
                <img src="${mainImg}" alt="${prop.titre}" loading="lazy">
                <div class="prop-badge-group">
                    <span class="badge-statut badge-${prop.type_transaction}">
                        <i data-lucide="tag"></i> ${prop.type_transaction === 'vente' ? 'Vente' : 'Location'}
                    </span>
                </div>
                <button class="btn-favori" data-id="${prop.id}"><i data-lucide="heart"></i></button>
            </div>
            <div class="prop-info">
                <div class="prop-prix">${formatPrice(prop.prix, prop.devise)}</div>
                <h3 class="prop-title">${prop.titre}</h3>
                <p class="prop-location"><i data-lucide="map-pin"></i> ${prop.zone_nom || prop.ville}</p>
                <div class="prop-specs">
                    <span><i data-lucide="bed"></i> ${prop.nb_chambres} ch.</span>
                    <span><i data-lucide="bath"></i> ${prop.nb_salles_bain} sdb</span>
                    <span><i data-lucide="maximize"></i> ${prop.superficie_m2} m²</span>
                </div>
                <a href="propriete.html?slug=${prop.slug}" class="btn-voir">Détails <i data-lucide="arrow-right"></i></a>
            </div>
        `;
        return div;
    };

    // Search input (debounced)
    let searchTimer = null;
    const rechercheInput = document.getElementById('recherche');
    if (rechercheInput) {
        rechercheInput.addEventListener('input', () => {
            clearTimeout(searchTimer);
            searchTimer = setTimeout(() => {
                filters.page = 0;
                loadProperties();
            }, 400);
        });
    }

    // Filter Listeners
    document.querySelectorAll('#filter-transaction .toggle').forEach(btn => {
        btn.addEventListener('click', () => {
            filters.transaction = btn.dataset.val;
            syncUI();
            loadProperties();
        });
    });

    // Type checkboxes
    document.querySelectorAll('#filter-types input').forEach(cb => {
        cb.addEventListener('change', () => {
            filters.types = Array.from(document.querySelectorAll('#filter-types input:checked')).map(input => input.value);
            loadProperties();
        });
    });

    // Chambres buttons
    document.querySelectorAll('#filter-chambres button').forEach(btn => {
        btn.addEventListener('click', () => {
            document.querySelectorAll('#filter-chambres button').forEach(b => b.classList.remove('active'));
            btn.classList.add('active');
            filters.chambres = parseInt(btn.dataset.val);
            loadProperties();
        });
    });

    // Meublé switch
    const meubleSwitch = document.getElementById('meuble');
    if (meubleSwitch) {
        meubleSwitch.addEventListener('change', () => {
            filters.meuble = meubleSwitch.checked;
            loadProperties();
        });
    }

    // Apply filters button
    if (btnApplyFilters) {
        btnApplyFilters.addEventListener('click', () => {
            filters.prix_min = parseInt(document.getElementById('prix-min').value) || null;
            filters.prix_max = parseInt(document.getElementById('prix-max-sidebar').value) || null;
            filters.meuble = document.getElementById('meuble').checked;
            loadProperties();
            
            // Close mobile filter sidebar if open
            if (filterSidebar && filterSidebar.classList.contains('active')) {
                filterSidebar.classList.remove('active');
                document.body.style.overflow = '';
            }
        });
    }

    // Reset filters button
    const btnResetFilters = document.getElementById('reset-filtres');
    if (btnResetFilters) {
        btnResetFilters.addEventListener('click', () => {
            filters.transaction = 'all';
            filters.types = [];
            filters.prix_min = null;
            filters.prix_max = null;
            filters.chambres = 0;
            filters.meuble = false;
            
            // Reset UI
            document.getElementById('prix-min').value = '';
            document.getElementById('prix-max-sidebar').value = '';
            document.getElementById('meuble').checked = false;
            document.querySelectorAll('#filter-types input').forEach(cb => cb.checked = false);
            document.querySelectorAll('#filter-chambres button').forEach(b => b.classList.remove('active'));
            document.querySelector('#filter-chambres button[data-val="0"]').classList.add('active');
            
            syncUI();
            loadProperties();
        });
    }

    // Mobile filter toggle
    const btnMobileFilters = document.getElementById('btn-filtres-mobile');
    const filterSidebar = document.getElementById('filter-sidebar');
    
    if (btnMobileFilters && filterSidebar) {
        btnMobileFilters.addEventListener('click', () => {
            filterSidebar.classList.add('active');
            document.body.style.overflow = 'hidden';
        });
    }
    
    // Close filters button (mobile)
    const btnCloseFilters = document.getElementById('close-filters-mobile');
    if (btnCloseFilters && filterSidebar) {
        btnCloseFilters.addEventListener('click', () => {
            filterSidebar.classList.remove('active');
            document.body.style.overflow = '';
        });
    }

    // Sort select
    const sortSelect = document.getElementById('tri');
    if (sortSelect) {
        sortSelect.addEventListener('change', () => {
            filters.tri = sortSelect.value;
            loadProperties();
        });
    }

    // View toggle (grid/list)
    const btnGrille = document.getElementById('btn-grille');
    const btnListe = document.getElementById('btn-liste');
    
    if (btnGrille && btnListe) {
        btnGrille.addEventListener('click', () => {
            btnGrille.classList.add('active');
            btnListe.classList.remove('active');
            catalogGrid.classList.remove('list-view');
            catalogGrid.classList.add('grid-view');
        });
        
        btnListe.addEventListener('click', () => {
            btnListe.classList.add('active');
            btnGrille.classList.remove('active');
            catalogGrid.classList.remove('grid-view');
            catalogGrid.classList.add('list-view');
        });
    }

    syncUI();
    loadProperties();
});
