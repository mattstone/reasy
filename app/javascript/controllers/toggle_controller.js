import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["content", "trigger"]

  toggle() {
    const content = this.contentTarget
    const isHidden = content.hidden

    content.hidden = !isHidden

    // Update trigger aria-expanded if it exists
    if (this.hasTriggerTarget) {
      this.triggerTarget.setAttribute("aria-expanded", isHidden)
    }
  }

  show() {
    this.contentTarget.hidden = false
    if (this.hasTriggerTarget) {
      this.triggerTarget.setAttribute("aria-expanded", "true")
    }
  }

  hide() {
    this.contentTarget.hidden = true
    if (this.hasTriggerTarget) {
      this.triggerTarget.setAttribute("aria-expanded", "false")
    }
  }
}
