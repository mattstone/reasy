import { Controller } from "@hotwired/stimulus"

// Manages user sidebar navigation active state during Turbo Frame navigation
export default class extends Controller {
  static targets = ["link"]
  static values = { currentPath: String }

  connect() {
    this.updateActiveState(this.currentPathValue)

    // Listen for Turbo frame navigation to update active state
    document.addEventListener("turbo:frame-load", this.handleFrameLoad.bind(this))
  }

  disconnect() {
    document.removeEventListener("turbo:frame-load", this.handleFrameLoad.bind(this))
  }

  handleFrameLoad(event) {
    // Only handle our main_content frame
    if (event.target.id === "main_content") {
      // Get the new URL from the frame's src or from history
      const newPath = window.location.pathname
      this.updateActiveState(newPath)
    }
  }

  updateActiveState(currentPath) {
    this.linkTargets.forEach(link => {
      const linkPath = link.dataset.path

      // Check for exact match or if current path starts with link path (for nested routes)
      const isActive = this.isPathActive(linkPath, currentPath)

      if (isActive) {
        link.classList.add("active")
      } else {
        link.classList.remove("active")
      }
    })
  }

  isPathActive(linkPath, currentPath) {
    // Exact match
    if (linkPath === currentPath) return true

    // Handle special cases for root dashboard
    if (linkPath === "/dashboard" && currentPath === "/dashboard") {
      return true
    }

    // For detail pages (e.g., /properties/1), match the index path
    // But be careful not to match partial paths
    if (currentPath.startsWith(linkPath + "/")) {
      return true
    }

    return false
  }
}
