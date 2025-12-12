import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { target: String }

  connect() {
    // Close on escape key
    this.boundHandleKeydown = this.handleKeydown.bind(this)
    document.addEventListener("keydown", this.boundHandleKeydown)
  }

  disconnect() {
    document.removeEventListener("keydown", this.boundHandleKeydown)
  }

  open() {
    const modal = this.targetValue ? document.getElementById(this.targetValue) : this.element
    modal.classList.add("open")
    document.body.style.overflow = "hidden"
  }

  close() {
    const modal = this.targetValue ? document.getElementById(this.targetValue) : this.element
    modal.classList.remove("open")
    document.body.style.overflow = ""
  }

  handleKeydown(event) {
    if (event.key === "Escape") {
      this.close()
    }
  }
}
