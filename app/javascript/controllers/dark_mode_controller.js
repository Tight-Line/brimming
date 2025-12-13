import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="dark-mode"
export default class extends Controller {
  static targets = ["lightIcon", "darkIcon"]

  connect() {
    this.updateIcons()
  }

  toggle() {
    const html = document.documentElement
    const isDark = html.classList.toggle("dark")

    // Save preference to cookie
    document.cookie = `dark_mode=${isDark}; path=/; max-age=${60 * 60 * 24 * 365}; SameSite=Lax`

    this.updateIcons()
  }

  updateIcons() {
    const isDark = document.documentElement.classList.contains("dark")

    if (this.hasLightIconTarget && this.hasDarkIconTarget) {
      if (isDark) {
        this.lightIconTarget.classList.add("nl-hidden")
        this.darkIconTarget.classList.remove("nl-hidden")
      } else {
        this.lightIconTarget.classList.remove("nl-hidden")
        this.darkIconTarget.classList.add("nl-hidden")
      }
    }
  }
}
