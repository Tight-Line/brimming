import { Controller } from "@hotwired/stimulus"

// Editor controller for markdown editing with preview
// Supports three modes: plain, markdown (write), and preview
export default class extends Controller {
  static targets = ["textarea", "preview", "modeButtons"]
  static values = {
    mode: { type: String, default: "plain" },
    previewPath: String
  }

  connect() {
    this.updateModeUI()
  }

  setModePlain(event) {
    event?.preventDefault()
    this.modeValue = "plain"
    this.updateModeUI()
  }

  setModeMarkdown(event) {
    event?.preventDefault()
    this.modeValue = "markdown"
    this.updateModeUI()
  }

  setModePreview(event) {
    event?.preventDefault()
    this.modeValue = "preview"
    this.updateModeUI()
    this.renderPreview()
  }

  updateModeUI() {
    // Update button states
    const buttons = this.modeButtonsTarget.querySelectorAll("button")
    buttons.forEach(btn => {
      btn.classList.toggle("active", btn.dataset.mode === this.modeValue)
    })

    // Show/hide textarea and preview
    if (this.hasPreviewTarget) {
      if (this.modeValue === "preview") {
        this.textareaTarget.style.display = "none"
        this.previewTarget.style.display = "block"
      } else {
        this.textareaTarget.style.display = "block"
        this.previewTarget.style.display = "none"
      }
    }
  }

  async renderPreview() {
    if (!this.hasPreviewTarget) return

    const text = this.textareaTarget.value
    if (!text.trim()) {
      this.previewTarget.innerHTML = '<p class="text-muted">Nothing to preview</p>'
      return
    }

    // For plain mode, just escape and wrap in paragraphs
    if (this.modeValue === "preview" && this.previousMode === "plain") {
      this.previewTarget.innerHTML = this.escapeAndFormat(text)
      return
    }

    // Fetch markdown preview from server
    try {
      const response = await fetch(this.previewPathValue || "/markdown/preview", {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "X-CSRF-Token": document.querySelector('meta[name="csrf-token"]')?.content
        },
        body: JSON.stringify({ text })
      })

      if (response.ok) {
        const data = await response.json()
        this.previewTarget.innerHTML = data.html
      } else {
        this.previewTarget.innerHTML = '<p class="text-muted">Preview unavailable</p>'
      }
    } catch (error) {
      // Fallback: simple client-side preview
      this.previewTarget.innerHTML = this.escapeAndFormat(text)
    }
  }

  escapeAndFormat(text) {
    const escaped = text
      .replace(/&/g, "&amp;")
      .replace(/</g, "&lt;")
      .replace(/>/g, "&gt;")
    return escaped.split("\n\n").map(p => `<p>${p.replace(/\n/g, "<br>")}</p>`).join("")
  }

  // Track previous mode for preview rendering
  modeValueChanged(value, previousValue) {
    this.previousMode = previousValue
  }
}
