import { Controller } from "@hotwired/stimulus"

// Manages admin sidebar navigation active state during Turbo Frame navigation
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
    // Only handle our admin_content frame
    if (event.target.id === "admin_content") {
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

    // Handle special cases for section root paths
    // Business section
    if (linkPath === "/admin/business" &&
        (currentPath === "/admin/business" || currentPath === "/admin/business/dashboard")) {
      return true
    }

    // System section
    if (linkPath === "/admin/system" &&
        (currentPath === "/admin/system" || currentPath === "/admin/system/dashboard")) {
      return true
    }

    // Dashboard
    if (linkPath === "/admin" && currentPath === "/admin") {
      return true
    }

    // For detail pages (e.g., /admin/users/1), match the index path
    if (currentPath.startsWith(linkPath + "/") && !linkPath.includes("/business") && !linkPath.includes("/system")) {
      return true
    }

    return false
  }
}
