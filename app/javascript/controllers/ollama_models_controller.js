import { Controller } from "@hotwired/stimulus"

// Handles dynamic Ollama model discovery and selection
export default class extends Controller {
  static targets = ["modelSelect", "modelInput", "modelStatus", "endpointInput", "modelGroup"]
  static values = { providerType: String }

  connect() {
    // Only run for Ollama providers
    if (this.providerTypeValue !== "ollama") return

    // Auto-detect Ollama on page load
    this.detectOllama()
  }

  async detectOllama() {
    this.updateStatus("Detecting Ollama instance...")

    try {
      const response = await fetch("/admin/llm_providers/ollama_models")

      if (response.ok) {
        const data = await response.json()
        this.populateModels(data.models)

        // Update endpoint field if auto-detected
        if (this.hasEndpointInputTarget && data.endpoint) {
          this.endpointInputTarget.value = data.endpoint
        }

        this.updateStatus(`Connected to Ollama at ${data.endpoint}. ${data.models.length} model(s) available.`)
      } else {
        const data = await response.json()
        this.handleNoOllama(data.error || "Ollama not found")
      }
    } catch (error) {
      this.handleNoOllama("Failed to detect Ollama: " + error.message)
    }
  }

  async endpointChanged() {
    const endpoint = this.endpointInputTarget.value.trim()
    if (!endpoint) return

    this.updateStatus("Connecting to Ollama...")

    try {
      const response = await fetch(`/admin/llm_providers/ollama_models?endpoint=${encodeURIComponent(endpoint)}`)

      if (response.ok) {
        const data = await response.json()
        this.populateModels(data.models)
        this.updateStatus(`Connected! ${data.models.length} model(s) available.`)
      } else {
        const data = await response.json()
        this.handleNoOllama(data.error || "Cannot connect to Ollama")
      }
    } catch (error) {
      this.handleNoOllama("Connection failed: " + error.message)
    }
  }

  populateModels(models) {
    if (!this.hasModelSelectTarget) return

    const select = this.modelSelectTarget
    select.innerHTML = ""

    if (models.length === 0) {
      select.innerHTML = '<option value="">No models found - pull a model first</option>'
      return
    }

    // Add placeholder
    const placeholder = document.createElement("option")
    placeholder.value = ""
    placeholder.textContent = "Select a model..."
    select.appendChild(placeholder)

    // Add models with details
    models.forEach(model => {
      const option = document.createElement("option")
      option.value = model.name

      let label = model.name
      if (model.parameter_size) {
        label += ` (${model.parameter_size})`
      }
      option.textContent = label

      select.appendChild(option)
    })

    // Show the select
    select.style.display = ""
  }

  selectModel() {
    if (!this.hasModelSelectTarget || !this.hasModelInputTarget) return

    const selectedValue = this.modelSelectTarget.value
    if (selectedValue) {
      this.modelInputTarget.value = selectedValue
    }
  }

  handleNoOllama(message) {
    if (this.hasModelSelectTarget) {
      this.modelSelectTarget.innerHTML = '<option value="">Enter model name below</option>'
    }
    this.updateStatus(message + " You can still enter a model name manually.")
  }

  updateStatus(message) {
    if (this.hasModelStatusTarget) {
      this.modelStatusTarget.textContent = message
    }
  }
}
