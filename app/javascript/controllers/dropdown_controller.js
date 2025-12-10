import { Controller } from "@hotwired/stimulus"

// Dropdown menu controller for hamburger menus and other dropdowns
// Usage:
//   <div data-controller="dropdown">
//     <button data-action="dropdown#toggle" data-dropdown-target="button" aria-expanded="false">Menu</button>
//     <div data-dropdown-target="menu" class="dropdown-menu">...</div>
//   </div>
export default class extends Controller {
  static targets = ["button", "menu"]

  connect() {
    // Bind the click outside handler so we can remove it later
    this.clickOutsideHandler = this.clickOutside.bind(this)
    this.keydownHandler = this.handleKeydown.bind(this)
  }

  disconnect() {
    this.close()
  }

  toggle(event) {
    event.preventDefault()
    event.stopPropagation()

    if (this.isOpen) {
      this.close()
    } else {
      this.open()
    }
  }

  open() {
    this.menuTarget.classList.add("dropdown-menu-visible")
    this.buttonTarget.setAttribute("aria-expanded", "true")

    // Add listeners for closing
    document.addEventListener("click", this.clickOutsideHandler)
    document.addEventListener("keydown", this.keydownHandler)
  }

  close() {
    this.menuTarget.classList.remove("dropdown-menu-visible")
    this.buttonTarget.setAttribute("aria-expanded", "false")

    // Remove listeners
    document.removeEventListener("click", this.clickOutsideHandler)
    document.removeEventListener("keydown", this.keydownHandler)
  }

  clickOutside(event) {
    // Close if click is outside the dropdown
    if (!this.element.contains(event.target)) {
      this.close()
    }
  }

  handleKeydown(event) {
    if (event.key === "Escape") {
      this.close()
      this.buttonTarget.focus()
    }
  }

  get isOpen() {
    return this.menuTarget.classList.contains("dropdown-menu-visible")
  }
}
