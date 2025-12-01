import { Controller } from "@hotwired/stimulus"

// Controller for article form that toggles between text editor and file upload
export default class extends Controller {
  static targets = ["textField", "fileField", "modeToggle"]

  connect() {
    this.toggleMode()
  }

  toggleMode() {
    const selectedMode = this.element.querySelector("input[name='article[input_mode]']:checked")?.value
    const isFileMode = selectedMode === "file"

    if (this.hasTextFieldTarget) {
      this.textFieldTarget.style.display = isFileMode ? "none" : "block"
    }
    if (this.hasFileFieldTarget) {
      this.fileFieldTarget.style.display = isFileMode ? "block" : "none"
    }
  }
}
