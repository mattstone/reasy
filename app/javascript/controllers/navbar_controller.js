import { Controller } from "@hotwired/stimulus"

// Controls mobile navigation toggle and scroll effects
export default class extends Controller {
  static targets = []

  connect() {
    this.setupScrollListener()
  }

  disconnect() {
    window.removeEventListener("scroll", this.handleScroll)
  }

  setupScrollListener() {
    this.handleScroll = this.handleScroll.bind(this)
    window.addEventListener("scroll", this.handleScroll, { passive: true })
  }

  handleScroll() {
    const nav = this.element
    if (window.scrollY > 50) {
      nav.classList.add("r5-nav-scrolled")
    } else {
      nav.classList.remove("r5-nav-scrolled")
    }
  }

  toggle() {
    const navLinks = this.element.querySelector(".r5-nav-links")
    const toggleBtn = this.element.querySelector(".r5-nav-toggle")

    if (navLinks) {
      navLinks.classList.toggle("r5-nav-links-open")
    }
    if (toggleBtn) {
      toggleBtn.classList.toggle("r5-nav-toggle-open")
    }
  }
}
