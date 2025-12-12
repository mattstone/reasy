import { Controller } from "@hotwired/stimulus"

// Handles homepage-specific animations and interactions
export default class extends Controller {
  connect() {
    this.setupIntersectionObserver()
    this.animateStatsOnScroll()
  }

  disconnect() {
    if (this.observer) {
      this.observer.disconnect()
    }
  }

  setupIntersectionObserver() {
    this.observer = new IntersectionObserver((entries) => {
      entries.forEach(entry => {
        if (entry.isIntersecting) {
          entry.target.classList.add("r5-visible")
        }
      })
    }, {
      threshold: 0.1,
      rootMargin: "0px 0px -50px 0px"
    })

    // Observe all animatable elements
    this.element.querySelectorAll("[data-animate]").forEach(el => {
      this.observer.observe(el)
    })
  }

  animateStatsOnScroll() {
    const statsSection = this.element.querySelector(".r5-proof-bar")
    if (!statsSection) return

    const statsObserver = new IntersectionObserver((entries) => {
      entries.forEach(entry => {
        if (entry.isIntersecting) {
          this.animateNumbers()
          statsObserver.disconnect()
        }
      })
    }, { threshold: 0.5 })

    statsObserver.observe(statsSection)
  }

  animateNumbers() {
    const statNumbers = this.element.querySelectorAll(".r5-stat-number")

    statNumbers.forEach(el => {
      const text = el.textContent
      const match = text.match(/[\d.]+/)
      if (!match) return

      const targetValue = parseFloat(match[0])
      const prefix = text.slice(0, text.indexOf(match[0]))
      const suffix = text.slice(text.indexOf(match[0]) + match[0].length)
      const isDecimal = text.includes(".")
      const duration = 1500
      const startTime = performance.now()

      const animate = (currentTime) => {
        const elapsed = currentTime - startTime
        const progress = Math.min(elapsed / duration, 1)
        // Ease out cubic
        const easeProgress = 1 - Math.pow(1 - progress, 3)
        const currentValue = targetValue * easeProgress

        if (isDecimal) {
          el.textContent = prefix + currentValue.toFixed(1) + suffix
        } else {
          el.textContent = prefix + Math.round(currentValue) + suffix
        }

        if (progress < 1) {
          requestAnimationFrame(animate)
        }
      }

      requestAnimationFrame(animate)
    })
  }
}
