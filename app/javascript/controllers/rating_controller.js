import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["star", "input", "label"]

  connect() {
    this.updateStars()
  }

  updateStars() {
    const checkedInput = this.inputTargets.find(input => input.checked)
    const value = checkedInput ? parseInt(checkedInput.value) : 0

    this.starTargets.forEach((star, index) => {
      const starValue = parseInt(star.dataset.value)
      if (starValue <= value) {
        star.style.color = "#FFB800"
        star.style.fill = "#FFB800"
      } else {
        star.style.color = ""
        star.style.fill = "none"
      }
    })

    if (this.hasLabelTarget) {
      const labels = ["", "Poor", "Fair", "Good", "Very Good", "Excellent"]
      this.labelTarget.textContent = value > 0 ? labels[value] : "Select a rating"
    }
  }

  select(event) {
    const star = event.currentTarget.querySelector("[data-rating-target='star']")
    const value = parseInt(star.dataset.value)

    // Find and check the corresponding input
    const input = this.inputTargets.find(input => parseInt(input.value) === value)
    if (input) {
      input.checked = true
      this.updateStars()
    }
  }

  hover(event) {
    const star = event.currentTarget.querySelector("[data-rating-target='star']")
    const hoverValue = parseInt(star.dataset.value)

    this.starTargets.forEach(s => {
      const starValue = parseInt(s.dataset.value)
      if (starValue <= hoverValue) {
        s.style.color = "#FFB800"
        s.style.fill = "#FFB800"
      } else {
        s.style.color = ""
        s.style.fill = "none"
      }
    })
  }

  leave() {
    this.updateStars()
  }
}
