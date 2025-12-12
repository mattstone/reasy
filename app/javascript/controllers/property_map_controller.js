import { Controller } from "@hotwired/stimulus"

// Controls the interactive property map
export default class extends Controller {
  static targets = [
    "map",
    "propertyList",
    "propertyCount",
    "searchInput",
    "typeFilter",
    "bedroomsFilter",
    "priceFilter"
  ]

  static values = {
    propertiesUrl: String
  }

  connect() {
    // Wait for Leaflet to load
    if (typeof L !== "undefined") {
      this.initializeMap()
    } else {
      // If Leaflet isn't loaded yet, wait for it
      window.addEventListener("load", () => this.initializeMap())
    }

    this.markers = {}
    this.activePropertyId = null
  }

  disconnect() {
    if (this.map) {
      this.map.remove()
    }
  }

  initializeMap() {
    if (!this.hasMapTarget || this.map) return

    // Initialize map centered on Sydney, Australia
    this.map = L.map(this.mapTarget, {
      zoomControl: false
    }).setView([-33.8688, 151.2093], 12)

    // Add zoom control to bottom right
    L.control.zoom({ position: "bottomright" }).addTo(this.map)

    // Add tile layer (OpenStreetMap)
    L.tileLayer("https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png", {
      maxZoom: 19,
      attribution: '&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors'
    }).addTo(this.map)

    // Load properties and add markers
    this.loadPropertiesFromDOM()

    // Update markers when map moves
    this.map.on("moveend", () => this.onMapMove())
  }

  loadPropertiesFromDOM() {
    // Get property data from list items in sidebar
    const items = this.propertyListTarget.querySelectorAll("[data-property-id]")

    items.forEach(item => {
      const id = item.dataset.propertyId
      const lat = parseFloat(item.dataset.lat)
      const lng = parseFloat(item.dataset.lng)

      if (lat && lng && !isNaN(lat) && !isNaN(lng)) {
        this.addMarker(id, lat, lng, item)
      }
    })

    // Fit map to markers if we have any
    if (Object.keys(this.markers).length > 0) {
      const group = new L.featureGroup(Object.values(this.markers))
      this.map.fitBounds(group.getBounds().pad(0.1))
    }
  }

  addMarker(id, lat, lng, listItem) {
    // Get property info for popup
    const price = listItem.querySelector(".map-property-price")?.textContent || ""
    const address = listItem.querySelector(".map-property-address")?.textContent || ""
    const features = listItem.querySelector(".map-property-features")?.innerHTML || ""

    // Determine marker type based on match criteria
    // For now, use "other" as default - in production, this would be based on user preferences
    const markerType = this.getMarkerType(listItem)

    // Create custom icon
    const icon = this.createMarkerIcon(price, markerType)

    // Create marker
    const marker = L.marker([lat, lng], { icon })
      .addTo(this.map)
      .bindPopup(this.createPopup(id, price, address, features, listItem))

    // Store reference
    this.markers[id] = marker
    marker.propertyId = id
    marker.markerType = markerType

    // Click handler
    marker.on("click", () => {
      this.scrollToProperty(id)
      this.setActiveProperty(id)
    })
  }

  getMarkerType(listItem) {
    // In a real implementation, this would compare property to user preferences
    // For now, randomly assign for demonstration
    const types = ["match", "price", "other"]
    return types[Math.floor(Math.random() * types.length)]
  }

  createMarkerIcon(price, type) {
    const colors = {
      match: "#34C759",  // Green
      price: "#FF9500",  // Orange/Yellow
      other: "#007AFF"   // Blue
    }

    const color = colors[type] || colors.other

    return L.divIcon({
      className: "map-price-marker-wrapper",
      html: `<div class="map-price-marker map-price-marker-${type}">${price}</div>`,
      iconSize: null,
      iconAnchor: [50, 20]
    })
  }

  createPopup(id, price, address, features, listItem) {
    const imageEl = listItem.querySelector(".map-property-image")
    const imageSrc = imageEl?.tagName === "IMG" ? imageEl.src : ""
    const imageStyle = imageEl?.tagName === "DIV" ? imageEl.getAttribute("style") : ""

    return `
      <div class="map-popup">
        ${imageSrc
          ? `<img src="${imageSrc}" class="map-popup-image" alt="${address}">`
          : `<div class="map-popup-image" style="${imageStyle}"></div>`
        }
        <div class="map-popup-price">${price}</div>
        <div class="map-popup-address">${address}</div>
        <div class="map-popup-features">${features}</div>
        <a href="/properties/${id}" class="btn btn-primary map-popup-btn">View Property</a>
      </div>
    `
  }

  scrollToProperty(id) {
    const item = this.propertyListTarget.querySelector(`[data-property-id="${id}"]`)
    if (item) {
      item.scrollIntoView({ behavior: "smooth", block: "nearest" })
    }
  }

  setActiveProperty(id) {
    // Remove active class from previous
    const prevActive = this.propertyListTarget.querySelector(".map-property-item.active")
    if (prevActive) {
      prevActive.classList.remove("active")
    }

    // Add active class to new
    const item = this.propertyListTarget.querySelector(`[data-property-id="${id}"]`)
    if (item) {
      item.classList.add("active")
    }

    this.activePropertyId = id
  }

  highlightProperty(event) {
    const id = event.currentTarget.dataset.propertyId
    this.setActiveProperty(id)

    // Pan to marker
    const marker = this.markers[id]
    if (marker) {
      this.map.panTo(marker.getLatLng())
      marker.openPopup()
    }
  }

  showPropertyOnMap(event) {
    const id = event.currentTarget.dataset.propertyId
    const marker = this.markers[id]

    if (marker) {
      // Highlight marker
      marker.setZIndexOffset(1000)
    }
  }

  resetMarker(event) {
    const id = event.currentTarget.dataset.propertyId
    const marker = this.markers[id]

    if (marker && id !== this.activePropertyId) {
      marker.setZIndexOffset(0)
    }
  }

  onMapMove() {
    // Could implement bounds-based loading here
    // For now, all properties are loaded upfront
  }

  searchLocation() {
    const query = this.searchInputTarget.value.trim()
    if (!query) return

    // Use Nominatim for geocoding (free, but respect usage policy)
    fetch(`https://nominatim.openstreetmap.org/search?format=json&q=${encodeURIComponent(query)}, Australia`)
      .then(response => response.json())
      .then(data => {
        if (data && data.length > 0) {
          const { lat, lon } = data[0]
          this.map.setView([lat, lon], 14)
        } else {
          alert("Location not found. Try a different search term.")
        }
      })
      .catch(error => {
        console.error("Geocoding error:", error)
      })
  }

  filterByType(event) {
    this.applyFilters()
  }

  filterByBedrooms(event) {
    this.applyFilters()
  }

  filterByPrice(event) {
    this.applyFilters()
  }

  clearFilters() {
    if (this.hasTypeFilterTarget) this.typeFilterTarget.value = ""
    if (this.hasBedroomsFilterTarget) this.bedroomsFilterTarget.value = ""
    if (this.hasPriceFilterTarget) this.priceFilterTarget.value = ""

    this.applyFilters()
  }

  applyFilters() {
    const params = new URLSearchParams()

    if (this.hasTypeFilterTarget && this.typeFilterTarget.value) {
      params.set("property_type", this.typeFilterTarget.value)
    }
    if (this.hasBedroomsFilterTarget && this.bedroomsFilterTarget.value) {
      params.set("bedrooms", this.bedroomsFilterTarget.value)
    }
    if (this.hasPriceFilterTarget && this.priceFilterTarget.value) {
      params.set("price", this.priceFilterTarget.value)
    }

    // Reload page with filters (could be AJAX in future)
    const url = new URL(window.location.href)
    url.search = params.toString()
    window.location.href = url.toString()
  }
}
