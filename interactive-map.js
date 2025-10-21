// Interactive India Map with Saree Information
class IndiaSareeMap {
    constructor() {
        this.map = null;
        this.stateData = this.getStateData();
        this.init();
    }

    init() {
        this.createMap();
        this.loadIndiaData();
    }

    createMap() {
        // Create Leaflet map with restricted boundaries for India
        this.map = L.map('indiaMapContainer', {
            center: [20.5937, 78.9629], // Center of India
            zoom: 5,
            minZoom: 4,
            maxZoom: 8,
            zoomControl: true,
            scrollWheelZoom: true,
            doubleClickZoom: true,
            boxZoom: false, // Disable box zoom
            keyboard: true,
            dragging: true,
            touchZoom: true,
            maxBounds: [
                [6.0, 68.0], // Southwest corner (south of India, west of India)
                [37.0, 97.0]  // Northeast corner (north of India, east of India)
            ],
            maxBoundsViscosity: 1.0 // Strict boundary enforcement
        });

        // Add tile layer with restricted zoom
        L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
            attribution: '© OpenStreetMap contributors',
            maxZoom: 8,
            minZoom: 4
        }).addTo(this.map);

        // Style the map container
        this.map.getContainer().style.borderRadius = '12px';
        this.map.getContainer().style.overflow = 'hidden';
        
        // Add India focus indicator
        this.addIndiaFocusIndicator();
    }

    async loadIndiaData() {
        try {
            // Hide loading spinner
            const loadingElement = document.getElementById('mapLoading');
            if (loadingElement) {
                loadingElement.style.display = 'none';
            }

            // Create state markers with saree information
            this.addStateMarkers();

        } catch (error) {
            console.error('Error loading map data:', error);
            this.showError();
        }
    }

    addStateMarkers() {
        const stateMarkers = [
            { name: 'Gujarat', lat: 23.0225, lng: 72.5714, sarees: ['Patola', 'Bandhani', 'Kutch Embroidery'] },
            { name: 'Maharashtra', lat: 19.7515, lng: 75.7139, sarees: ['Paithani', 'Narayan Peth', 'Karvat Kati'] },
            { name: 'Rajasthan', lat: 27.0238, lng: 74.2179, sarees: ['Leheriya', 'Bandhani', 'Kota Doria'] },
            { name: 'Punjab', lat: 30.7333, lng: 75.8667, sarees: ['Phulkari', 'Chope', 'Bagh'] },
            { name: 'Uttar Pradesh', lat: 26.8467, lng: 80.9462, sarees: ['Banarasi', 'Chikankari', 'Zardozi'] },
            { name: 'West Bengal', lat: 22.9868, lng: 88.3647, sarees: ['Jamdani', 'Tant', 'Baluchari'] },
            { name: 'Assam', lat: 26.2006, lng: 92.9376, sarees: ['Muga Silk', 'Eri Silk', 'Pat Silk'] },
            { name: 'Karnataka', lat: 15.3173, lng: 75.7139, sarees: ['Mysore Silk', 'Ilkal', 'Molakalmuru'] },
            { name: 'Kerala', lat: 10.8505, lng: 76.2711, sarees: ['Kasavu', 'Kanjeevaram', 'Balaramapuram'] },
            { name: 'Tamil Nadu', lat: 11.1271, lng: 78.6569, sarees: ['Kanchipuram', 'Coimbatore Cotton', 'Madurai Cotton'] },
            { name: 'Telangana', lat: 18.1124, lng: 79.0193, sarees: ['Pochampally', 'Gadwal', 'Venkatagiri'] },
            { name: 'Andhra Pradesh', lat: 15.9129, lng: 79.7400, sarees: ['Mangalagiri', 'Uppada', 'Dharmavaram'] },
            { name: 'Odisha', lat: 20.9517, lng: 85.0985, sarees: ['Sambalpuri', 'Bomkai', 'Berhampur Silk'] },
            { name: 'Bihar', lat: 25.0961, lng: 85.3131, sarees: ['Tussar Silk', 'Bhagalpur Silk', 'Madhubani'] },
            { name: 'Madhya Pradesh', lat: 22.9734, lng: 77.6561, sarees: ['Chanderi', 'Maheshwari', 'Bagru Print'] }
        ];

        stateMarkers.forEach(state => {
            const marker = L.circleMarker([state.lat, state.lng], {
                radius: 12,
                fillColor: '#8b1538',
                color: '#d4af37',
                weight: 3,
                opacity: 1,
                fillOpacity: 0.8
            }).addTo(this.map);

            // Create popup content
            const popupContent = `
                <div style="text-align: center; padding: 10px; min-width: 200px;">
                    <h3 style="color: #8b1538; margin-bottom: 10px; font-size: 1.2rem;">${state.name}</h3>
                    <div style="margin-bottom: 10px;">
                        <strong style="color: #d4af37;">Famous Sarees:</strong>
                    </div>
                    <ul style="list-style: none; padding: 0; margin: 0;">
                        ${state.sarees.map(saree => `<li style="color: #8b1538; margin: 5px 0; font-size: 0.9rem;">• ${saree}</li>`).join('')}
                    </ul>
                    <button onclick="window.scrollToSection('collections')" 
                            style="background: linear-gradient(135deg, #8b1538 0%, #a01e42 100%); 
                                   color: white; border: none; padding: 8px 16px; 
                                   border-radius: 20px; margin-top: 10px; cursor: pointer;
                                   font-weight: 600; box-shadow: 0 4px 15px rgba(139, 21, 56, 0.4);">
                        View Collections
                    </button>
                </div>
            `;

            marker.bindPopup(popupContent, {
                maxWidth: 300,
                className: 'custom-popup'
            });

            // Add hover effects
            marker.on('mouseover', function(e) {
                this.setStyle({
                    fillColor: '#d4af37',
                    color: '#8b1538',
                    radius: 15,
                    weight: 4
                });
            });

            marker.on('mouseout', function(e) {
                this.setStyle({
                    fillColor: '#8b1538',
                    color: '#d4af37',
                    radius: 12,
                    weight: 3
                });
            });

            marker.on('click', function(e) {
                // Add click effect
                this.setStyle({
                    fillColor: '#d4af37',
                    color: '#8b1538',
                    radius: 16,
                    weight: 5
                });
                
                // Reset after animation
                setTimeout(() => {
                    this.setStyle({
                        fillColor: '#8b1538',
                        color: '#d4af37',
                        radius: 12,
                        weight: 3
                    });
                }, 300);
            });
        });

        // Fit map to show all markers within India boundaries
        const group = new L.featureGroup(stateMarkers.map(state => 
            L.marker([state.lat, state.lng])
        ));
        this.map.fitBounds(group.getBounds().pad(0.05), {
            maxZoom: 6 // Limit the fit bounds zoom level
        });
        
        // Ensure map stays within India boundaries
        this.map.on('moveend', () => {
            const bounds = this.map.getBounds();
            const indiaBounds = L.latLngBounds([6.0, 68.0], [37.0, 97.0]);
            
            if (!indiaBounds.contains(bounds)) {
                this.map.fitBounds(indiaBounds);
            }
        });
    }

    addIndiaFocusIndicator() {
        // Add a subtle overlay to indicate India focus
        const indiaOverlay = L.rectangle([
            [6.0, 68.0], // Southwest corner
            [37.0, 97.0]  // Northeast corner
        ], {
            color: '#d4af37',
            weight: 3,
            opacity: 0.8,
            fillColor: 'transparent',
            fillOpacity: 0,
            dashArray: '10, 10'
        }).addTo(this.map);
        
        // Add a title overlay
        const titleOverlay = L.control({position: 'topright'});
        titleOverlay.onAdd = function(map) {
            const div = L.DomUtil.create('div', 'india-map-title');
            div.innerHTML = `
                <div style="
                    background: linear-gradient(135deg, #8b1538 0%, #a01e42 100%);
                    color: white;
                    padding: 8px 12px;
                    border-radius: 20px;
                    font-size: 0.9rem;
                    font-weight: 600;
                    box-shadow: 0 4px 15px rgba(139, 21, 56, 0.4);
                    border: 2px solid #d4af37;
                    text-align: center;
                ">
                    🇮🇳 India Saree Map
                </div>
            `;
            return div;
        };
        titleOverlay.addTo(this.map);
    }

    getStateData() {
        return {
            'Gujarat': {
                sarees: ['Patola', 'Bandhani', 'Kutch Embroidery'],
                description: 'Famous for intricate tie-dye work and mirror work'
            },
            'Maharashtra': {
                sarees: ['Paithani', 'Narayan Peth', 'Karvat Kati'],
                description: 'Known for luxurious silk sarees with gold borders'
            },
            'Rajasthan': {
                sarees: ['Leheriya', 'Bandhani', 'Kota Doria'],
                description: 'Traditional tie-dye and lightweight cotton sarees'
            },
            'Punjab': {
                sarees: ['Phulkari', 'Chope', 'Bagh'],
                description: 'Embroidered sarees with vibrant floral patterns'
            },
            'Uttar Pradesh': {
                sarees: ['Banarasi', 'Chikankari', 'Zardozi'],
                description: 'Opulent silk sarees with intricate gold work'
            },
            'West Bengal': {
                sarees: ['Jamdani', 'Tant', 'Baluchari'],
                description: 'Fine muslin and cotton sarees with delicate weaving'
            },
            'Assam': {
                sarees: ['Muga Silk', 'Eri Silk', 'Pat Silk'],
                description: 'Unique silk varieties native to Assam'
            },
            'Karnataka': {
                sarees: ['Mysore Silk', 'Ilkal', 'Molakalmuru'],
                description: 'Pure silk sarees with traditional motifs'
            },
            'Kerala': {
                sarees: ['Kasavu', 'Kanjeevaram', 'Balaramapuram'],
                description: 'Gold-bordered sarees perfect for festivals'
            },
            'Tamil Nadu': {
                sarees: ['Kanchipuram', 'Coimbatore Cotton', 'Madurai Cotton'],
                description: 'Temple borders and pure silk sarees'
            },
            'Telangana': {
                sarees: ['Pochampally', 'Gadwal', 'Venkatagiri'],
                description: 'Ikat weaving and traditional designs'
            },
            'Andhra Pradesh': {
                sarees: ['Mangalagiri', 'Uppada', 'Dharmavaram'],
                description: 'Cotton and silk sarees with unique weaving'
            },
            'Odisha': {
                sarees: ['Sambalpuri', 'Bomkai', 'Berhampur Silk'],
                description: 'Traditional ikat and silk sarees'
            },
            'Bihar': {
                sarees: ['Tussar Silk', 'Bhagalpur Silk', 'Madhubani'],
                description: 'Wild silk and hand-painted sarees'
            },
            'Madhya Pradesh': {
                sarees: ['Chanderi', 'Maheshwari', 'Bagru Print'],
                description: 'Lightweight cotton and silk sarees'
            }
        };
    }

    showError() {
        const loadingElement = document.getElementById('mapLoading');
        if (loadingElement) {
            loadingElement.innerHTML = `
                <i class="fas fa-exclamation-triangle" style="color: #8b1538;"></i>
                <p>Unable to load map. Please refresh the page.</p>
            `;
        }
    }
}

// Initialize map when DOM is loaded
document.addEventListener('DOMContentLoaded', function() {
    // Add custom popup styles
    const style = document.createElement('style');
    style.textContent = `
        .custom-popup .leaflet-popup-content-wrapper {
            background: linear-gradient(135deg, #fef7f0 0%, #f8f4f0 100%);
            border: 2px solid #d4af37;
            border-radius: 15px;
            box-shadow: 0 15px 35px rgba(139, 21, 56, 0.2);
        }
        
        .custom-popup .leaflet-popup-tip {
            background: #d4af37;
        }
        
        .custom-popup .leaflet-popup-close-button {
            color: #8b1538;
            font-size: 18px;
            font-weight: bold;
        }
        
        .custom-popup .leaflet-popup-close-button:hover {
            color: #d4af37;
        }
    `;
    document.head.appendChild(style);

    // Initialize the map
    new IndiaSareeMap();
});

// Make scrollToSection function available globally
window.scrollToSection = function(sectionId) {
    const element = document.getElementById(sectionId);
    if (element) {
        element.scrollIntoView({ behavior: 'smooth' });
    }
};