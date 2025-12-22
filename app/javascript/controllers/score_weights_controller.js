import { Controller } from "@hotwired/stimulus"

// Manages the custom score weights form for personalizing Reasy Score
export default class extends Controller {
  static targets = ["slider", "value", "total", "resetButton"]

  static values = {
    defaults: Object
  }

  connect() {
    this.updateTotal()
    this.updateResetButtonVisibility()
  }

  // Called when any slider value changes
  update(event) {
    const slider = event.target
    const valueDisplay = slider.closest('.weight-slider').querySelector('[data-score-weights-target="value"]')
    if (valueDisplay) {
      valueDisplay.textContent = slider.value + '%'
    }
    this.updateTotal()
    this.updateResetButtonVisibility()
  }

  // Update the total percentage display
  updateTotal() {
    const total = this.sliderTargets.reduce((sum, slider) => sum + parseInt(slider.value || 0), 0)

    if (this.hasTotalTarget) {
      this.totalTarget.textContent = total + '%'

      // Add visual feedback for the total
      if (total === 100) {
        this.totalTarget.classList.remove('text-warning', 'text-error')
        this.totalTarget.classList.add('text-success')
      } else if (total > 100) {
        this.totalTarget.classList.remove('text-success', 'text-warning')
        this.totalTarget.classList.add('text-error')
      } else {
        this.totalTarget.classList.remove('text-success', 'text-error')
        this.totalTarget.classList.add('text-warning')
      }
    }
  }

  // Check if current weights differ from defaults
  hasCustomWeights() {
    const defaults = this.defaultsValue || {}
    return this.sliderTargets.some(slider => {
      const component = this.getComponentFromSlider(slider)
      const defaultValue = defaults[component] || 0
      return parseInt(slider.value) !== defaultValue
    })
  }

  // Update reset button visibility
  updateResetButtonVisibility() {
    if (this.hasResetButtonTarget) {
      if (this.hasCustomWeights()) {
        this.resetButtonTarget.classList.remove('hidden')
      } else {
        this.resetButtonTarget.classList.add('hidden')
      }
    }
  }

  // Reset all sliders to default values
  reset(event) {
    event.preventDefault()
    const defaults = this.defaultsValue || {}

    this.sliderTargets.forEach(slider => {
      const component = this.getComponentFromSlider(slider)
      const defaultValue = defaults[component] || 10
      slider.value = defaultValue

      const valueDisplay = slider.closest('.weight-slider').querySelector('[data-score-weights-target="value"]')
      if (valueDisplay) {
        valueDisplay.textContent = defaultValue + '%'
      }
    })

    this.updateTotal()
    this.updateResetButtonVisibility()
  }

  // Extract component name from slider's name attribute
  getComponentFromSlider(slider) {
    const match = slider.name.match(/\[(\w+)\]$/)
    return match ? match[1] : null
  }
}
