import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["container", "form", "input"]
  static values = { conversationId: Number }

  connect() {
    this.scrollToBottom()
  }

  scrollToBottom() {
    if (this.hasContainerTarget) {
      this.containerTarget.scrollTop = this.containerTarget.scrollHeight
    }
  }

  autoResize(event) {
    const textarea = event.target
    textarea.style.height = "auto"
    textarea.style.height = Math.min(textarea.scrollHeight, 200) + "px"
  }

  handleKeydown(event) {
    // Submit on Enter (without Shift)
    if (event.key === "Enter" && !event.shiftKey) {
      event.preventDefault()
      this.formTarget.requestSubmit()
    }
  }

  clearForm(event) {
    if (event.detail.success) {
      this.inputTarget.value = ""
      this.inputTarget.style.height = "auto"

      // Scroll to bottom after message is added
      setTimeout(() => this.scrollToBottom(), 100)
    }
  }
}
