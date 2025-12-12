import { Controller } from "@hotwired/stimulus"

// Controller for article form that toggles between text editor, file upload, and webpage URL
export default class extends Controller {
  static targets = ["textField", "fileField", "webpageField", "modeToggle"]

  connect() {
    this.toggleMode()
  }

  toggleMode() {
    const selectedMode = this.element.querySelector("input[name='article[input_mode]']:checked")?.value

    if (this.hasTextFieldTarget) {
      this.textFieldTarget.style.display = selectedMode === "text" ? "block" : "none"
    }
    if (this.hasFileFieldTarget) {
      this.fileFieldTarget.style.display = selectedMode === "file" ? "block" : "none"
    }
    if (this.hasWebpageFieldTarget) {
      this.webpageFieldTarget.style.display = selectedMode === "webpage" ? "block" : "none"
    }
  }
}
