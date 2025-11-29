import { Controller } from "@hotwired/stimulus"

// User search type-ahead controller
// Provides autocomplete functionality for user selection
export default class extends Controller {
  static targets = ["input", "results", "hiddenInput"]
  static values = {
    url: String,
    exclude: { type: String, default: "" },
    minLength: { type: Number, default: 2 }
  }

  connect() {
    this.selectedIndex = -1
    this.debounceTimer = null
  }

  disconnect() {
    this.clearDebounce()
  }

  onInput() {
    this.clearDebounce()
    const query = this.inputTarget.value.trim()

    if (query.length < this.minLengthValue) {
      this.hideResults()
      return
    }

    // Debounce the search
    this.debounceTimer = setTimeout(() => {
      this.search(query)
    }, 200)
  }

  async search(query) {
    try {
      let url = `${this.urlValue}?q=${encodeURIComponent(query)}`
      if (this.excludeValue) {
        url += `&exclude=${encodeURIComponent(this.excludeValue)}`
      }

      const response = await fetch(url, {
        headers: {
          "Accept": "application/json",
          "X-CSRF-Token": document.querySelector('meta[name="csrf-token"]')?.content
        }
      })

      if (response.ok) {
        const users = await response.json()
        this.showResults(users)
      }
    } catch (error) {
      console.error("User search error:", error)
      this.hideResults()
    }
  }

  showResults(users) {
    if (users.length === 0) {
      this.resultsTarget.innerHTML = '<div class="typeahead-no-results">No users found</div>'
      this.resultsTarget.classList.add("typeahead-visible")
      return
    }

    this.selectedIndex = -1
    this.resultsTarget.innerHTML = users.map((user, index) => {
      const displayName = this.escapeHtml(user.display_name)
      const username = this.escapeHtml(user.username)
      const hasFullName = user.display_name !== user.username

      return `
        <div class="typeahead-item"
             data-user-id="${user.id}"
             data-user-name="${displayName}"
             data-index="${index}"
             data-action="click->user-search#selectResult mouseenter->user-search#highlightResult">
          ${hasFullName ? `<span class="typeahead-item-name">${displayName}</span> ` : ''}<span class="typeahead-item-username">@${username}</span>
        </div>
      `
    }).join("")

    this.resultsTarget.classList.add("typeahead-visible")
  }

  hideResults() {
    this.resultsTarget.classList.remove("typeahead-visible")
    this.resultsTarget.innerHTML = ""
    this.selectedIndex = -1
  }

  selectResult(event) {
    const item = event.currentTarget
    const userId = item.dataset.userId
    const userName = item.dataset.userName

    this.hiddenInputTarget.value = userId
    this.inputTarget.value = userName
    this.hideResults()
  }

  highlightResult(event) {
    const index = parseInt(event.currentTarget.dataset.index, 10)
    this.updateHighlight(index)
  }

  onKeydown(event) {
    const items = this.resultsTarget.querySelectorAll(".typeahead-item")
    if (items.length === 0) return

    switch (event.key) {
      case "ArrowDown":
        event.preventDefault()
        this.updateHighlight(Math.min(this.selectedIndex + 1, items.length - 1))
        break
      case "ArrowUp":
        event.preventDefault()
        this.updateHighlight(Math.max(this.selectedIndex - 1, 0))
        break
      case "Enter":
        event.preventDefault()
        if (this.selectedIndex >= 0 && items[this.selectedIndex]) {
          items[this.selectedIndex].click()
        }
        break
      case "Escape":
        this.hideResults()
        break
    }
  }

  updateHighlight(index) {
    const items = this.resultsTarget.querySelectorAll(".typeahead-item")
    items.forEach((item, i) => {
      item.classList.toggle("typeahead-item-highlighted", i === index)
    })
    this.selectedIndex = index
  }

  onBlur() {
    // Delay hiding to allow click events to fire
    setTimeout(() => {
      this.hideResults()
    }, 200)
  }

  clearDebounce() {
    if (this.debounceTimer) {
      clearTimeout(this.debounceTimer)
      this.debounceTimer = null
    }
  }

  escapeHtml(text) {
    const div = document.createElement("div")
    div.textContent = text
    return div.innerHTML
  }
}
