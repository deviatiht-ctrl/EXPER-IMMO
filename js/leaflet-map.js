/**
 * EXPER IMMO - Leaflet Maps Integration
 * Carte interactive gratuite avec Leaflet + OpenStreetMap
 */

// Configuration Leaflet
const MAP_CONFIG = {
    defaultCenter: [18.5944, -72.3074], // Haïti centre
    defaultZoom: 8,
    tileUrl: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
    attribution: '&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors'
};

class ExperMap {
    constructor(containerId, options = {}) {
        this.containerId = containerId;
        this.map = null;
        this.markers = [];
        this.options = {
            center: options.center || MAP_CONFIG.defaultCenter,
            zoom: options.zoom || MAP_CONFIG.defaultZoom,
            scrollWheelZoom: options.scrollWheelZoom || false
        };
    }

    // Initialiser la carte
    init() {
        const container = document.getElementById(this.containerId);
        if (!container) {
            console.error(`Container #${this.containerId} not found`);
            return null;
        }

        // Créer la carte
        this.map = L.map(this.containerId, {
            center: this.options.center,
            zoom: this.options.zoom,
            scrollWheelZoom: this.options.scrollWheelZoom
        });

        // Ajouter les tuiles OpenStreetMap
        L.tileLayer(MAP_CONFIG.tileUrl, {
            attribution: MAP_CONFIG.attribution,
            maxZoom: 19
        }).addTo(this.map);

        return this.map;
    }

    // Ajouter un marqueur
    addMarker(lat, lng, popupContent = '', options = {}) {
        if (!this.map) return null;

        const marker = L.marker([lat, lng], options).addTo(this.map);
        
        if (popupContent) {
            marker.bindPopup(popupContent);
        }

        this.markers.push(marker);
        return marker;
    }

    // Ajouter un marqueur personnalisé avec icône
    addCustomMarker(lat, lng, popupContent = '', iconUrl = null) {
        if (!this.map) return null;

        let icon = null;
        if (iconUrl) {
            icon = L.icon({
                iconUrl: iconUrl,
                iconSize: [32, 32],
                iconAnchor: [16, 32],
                popupAnchor: [0, -32]
            });
        }

        return this.addMarker(lat, lng, popupContent, { icon });
    }

    // Centrer sur une position
    setView(lat, lng, zoom = null) {
        if (!this.map) return;
        this.map.setView([lat, lng], zoom || this.map.getZoom());
    }

    // Ajuster pour voir tous les marqueurs
    fitBounds() {
        if (!this.map || this.markers.length === 0) return;
        
        const group = new L.featureGroup(this.markers);
        this.map.fitBounds(group.getBounds().pad(0.1));
    }

    // Géocoder une adresse (utiliser Nominatim)
    async geocode(address) {
        try {
            const response = await fetch(
                `https://nominatim.openstreetmap.org/search?format=json&q=${encodeURIComponent(address)}`
            );
            const data = await response.json();
            
            if (data && data.length > 0) {
                return {
                    lat: parseFloat(data[0].lat),
                    lng: parseFloat(data[0].lon),
                    display_name: data[0].display_name
                };
            }
            return null;
        } catch (error) {
            console.error('Geocoding error:', error);
            return null;
        }
    }

    // Créer un cercle (pour zone)
    addCircle(lat, lng, radius, options = {}) {
        if (!this.map) return null;
        
        return L.circle([lat, lng], {
            radius: radius,
            color: options.color || '#C53636',
            fillColor: options.fillColor || '#C53636',
            fillOpacity: options.fillOpacity || 0.2,
            ...options
        }).addTo(this.map);
    }

    // Détruire la carte
    destroy() {
        if (this.map) {
            this.map.remove();
            this.map = null;
        }
    }
}

// Fonction utilitaire pour créer une carte rapide
function createMap(containerId, lat, lng, zoom = 15) {
    const map = new ExperMap(containerId, { center: [lat, lng], zoom });
    map.init();
    return map;
}

// Exporter pour utilisation
window.ExperMap = ExperMap;
window.createMap = createMap;
