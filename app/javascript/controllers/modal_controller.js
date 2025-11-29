import { Controller } from "@hotwired/stimulus"

// Modal controller for sign-in and other modals
// Usage:
//   <div data-controller="modal" data-modal-open-class="modal-open">
//     <button data-action="modal#open">Open</button>
//     <div data-modal-target="dialog" class="modal">
//       <div class="modal-backdrop" data-action="click->modal#close"></div>
//       <div class="modal-content">
//         <button data-action="modal#close">×</button>
//         <!-- content -->
//       </div>
//     </div>
//   </div>
export default class extends Controller {
  static targets = ["dialog"]
  static classes = ["open"]
  static values = {
    returnUrl: String
  }

  connect() {
    // Close on escape key
    this.boundKeydown = this.handleKeydown.bind(this)
    document.addEventListener("keydown", this.boundKeydown)
  }

  disconnect() {
    document.removeEventListener("keydown", this.boundKeydown)
  }

  open(event) {
    event?.preventDefault()

    // Capture return URL from the triggering element or current page
    // Use pathname + search (not href) since server expects relative paths starting with /
    if (event?.currentTarget?.dataset?.returnUrl) {
      this.returnUrlValue = event.currentTarget.dataset.returnUrl
    } else if (!this.returnUrlValue) {
      this.returnUrlValue = window.location.pathname + window.location.search
    }

    // Update any return_to fields in forms within the modal
    this.updateReturnUrlFields()

    this.dialogTarget.classList.add("modal-visible")
    document.body.classList.add("modal-open")
    this.dialogTarget.querySelector("input:not([type='hidden'])")?.focus()
  }

  close(event) {
    event?.preventDefault()
    this.dialogTarget.classList.remove("modal-visible")
    document.body.classList.remove("modal-open")
  }

  handleKeydown(event) {
    if (event.key === "Escape" && this.dialogTarget.classList.contains("modal-visible")) {
      this.close()
    }
  }

  updateReturnUrlFields() {
    // Update hidden return_to fields in forms
    const returnFields = this.dialogTarget.querySelectorAll("input[name='return_to']")
    returnFields.forEach(field => {
      field.value = this.returnUrlValue
    })

    // Update sign-up link with return URL
    const signUpLinks = this.dialogTarget.querySelectorAll("a[data-sign-up-link]")
    signUpLinks.forEach(link => {
      const url = new URL(link.href, window.location.origin)
      url.searchParams.set("return_to", this.returnUrlValue)
      link.href = url.toString()
    })
  }
}
