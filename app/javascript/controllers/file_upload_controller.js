import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "label"]

  handleChange(event) {
    const file = event.target.files[0]

    if (file) {
      this.element.classList.add("has-file")

      if (this.hasLabelTarget) {
        this.labelTarget.textContent = file.name
      }
    } else {
      this.element.classList.remove("has-file")

      if (this.hasLabelTarget) {
        this.labelTarget.textContent = "Click to upload or drag and drop"
      }
    }
  }
}
