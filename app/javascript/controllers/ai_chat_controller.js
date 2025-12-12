import { Controller } from "@hotwired/stimulus"

// Controls AI chat interface interactions
export default class extends Controller {
  static targets = ["input", "messages", "sendButton", "typingIndicator"]

  connect() {
    this.focusInput()
    this.scrollToBottom()
  }

  focusInput() {
    if (this.hasInputTarget) {
      this.inputTarget.focus()
    }
  }

  scrollToBottom() {
    if (this.hasMessagesTarget) {
      this.messagesTarget.scrollTop = this.messagesTarget.scrollHeight
    }
  }

  resize() {
    if (!this.hasInputTarget) return

    const input = this.inputTarget
    input.style.height = "auto"
    input.style.height = Math.min(input.scrollHeight, 120) + "px"
  }

  keydown(event) {
    if (event.key === "Enter" && !event.shiftKey) {
      event.preventDefault()
      this.element.requestSubmit()
    }
  }

  submit() {
    this.showTypingIndicator()
    this.disableSendButton()
  }

  messageReceived() {
    this.hideTypingIndicator()
    this.enableSendButton()
    this.scrollToBottom()
    this.clearInput()
  }

  showTypingIndicator() {
    if (this.hasTypingIndicatorTarget) {
      this.typingIndicatorTarget.style.display = ""
    }
  }

  hideTypingIndicator() {
    if (this.hasTypingIndicatorTarget) {
      this.typingIndicatorTarget.style.display = "none"
    }
  }

  disableSendButton() {
    if (this.hasSendButtonTarget) {
      this.sendButtonTarget.disabled = true
    }
  }

  enableSendButton() {
    if (this.hasSendButtonTarget) {
      this.sendButtonTarget.disabled = false
    }
  }

  clearInput() {
    if (this.hasInputTarget) {
      this.inputTarget.value = ""
      this.resize()
    }
  }
}
