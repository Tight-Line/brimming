import { Controller } from "@hotwired/stimulus"

// Controller for toggling comment reply forms
export default class extends Controller {
  static targets = ["form"]

  toggle(event) {
    event.preventDefault()
    const form = this.formTarget
    const button = event.currentTarget

    if (form.style.display === "none") {
      form.style.display = "block"
      button.textContent = "Cancel"
      // Focus the textarea
      const textarea = form.querySelector("textarea")
      if (textarea) textarea.focus()
    } else {
      form.style.display = "none"
      button.textContent = "Reply"
    }
  }
}
