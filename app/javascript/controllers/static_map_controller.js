import { Controller } from "@hotwired/stimulus"

// Simple static map controller for displaying a single property location
export default class extends Controller {
  static values = {
    lat: Number,
    lng: Number,
    zoom: { type: Number, default: 15 }
  }

  connect() {
    this.loadLeaflet()
      .then(() => {
        this.initializeMap()
      })
      .catch((error) => {
        console.error("Failed to load Leaflet:", error)
      })
  }

  loadLeaflet() {
    return new Promise((resolve, reject) => {
      // Check if already loaded
      if (typeof L !== "undefined") {
        resolve()
        return
      }

      // Load CSS first
      if (!document.querySelector('link[href*="leaflet"]')) {
        const css = document.createElement("link")
        css.rel = "stylesheet"
        css.href = "https://unpkg.com/leaflet@1.9.4/dist/leaflet.css"
        css.crossOrigin = "anonymous"
        document.head.appendChild(css)
      }

      // Check if script already exists
      const existingScript = document.querySelector('script[src*="leaflet"]')

      if (existingScript) {
        if (typeof L !== "undefined") {
          resolve()
        } else {
          existingScript.addEventListener("load", () => resolve())
          existingScript.addEventListener("error", reject)

          // Poll in case events don't fire
          const checkL = setInterval(() => {
            if (typeof L !== "undefined") {
              clearInterval(checkL)
              resolve()
            }
          }, 100)

          setTimeout(() => {
            clearInterval(checkL)
            if (typeof L === "undefined") {
              reject(new Error("Leaflet load timeout"))
            }
          }, 10000)
        }
      } else {
        const script = document.createElement("script")
        script.src = "https://unpkg.com/leaflet@1.9.4/dist/leaflet.js"
        script.crossOrigin = "anonymous"
        script.onload = () => setTimeout(resolve, 50)
        script.onerror = () => reject(new Error("Failed to load Leaflet script"))
        document.head.appendChild(script)
      }
    })
  }

  disconnect() {
    if (this.map) {
      this.map.remove()
      this.map = null
    }
  }

  initializeMap() {
    if (!this.hasLatValue || !this.hasLngValue) {
      console.warn("Static map: Missing lat/lng values")
      return
    }

    const lat = this.latValue
    const lng = this.lngValue
    const zoom = this.zoomValue

    try {
      // Initialize map
      this.map = L.map(this.element, {
        zoomControl: true,
        scrollWheelZoom: false,
        dragging: true
      }).setView([lat, lng], zoom)

      // Add tile layer (OpenStreetMap)
      L.tileLayer("https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png", {
        maxZoom: 19,
        attribution: '&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a>'
      }).addTo(this.map)

      // Add marker
      L.marker([lat, lng]).addTo(this.map)

      // Invalidate size after a brief delay (fixes grey map issue)
      setTimeout(() => {
        if (this.map) {
          this.map.invalidateSize()
        }
      }, 100)

    } catch (error) {
      console.error("Error initializing static map:", error)
    }
  }
}
