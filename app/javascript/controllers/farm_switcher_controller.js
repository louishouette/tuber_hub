import { Controller } from "@hotwired/stimulus"

// Farm switcher controller - Business logic
export default class extends Controller {
  static targets = ["dropdown"]
  static values = {
    currentFarm: String,
    makeDefault: Boolean
  }

  // Event handlers registry
  #listeners = {}

  connect() {
    // Initialize event handling
    this.#on("farmSelected", this.handleFarmSelected.bind(this))
  }

  disconnect() {
    // Clean up event listeners
    this.#off("farmSelected")
  }
  
  // Simple event emitter implementation
  #on(event, callback) {
    if (!this.#listeners[event]) {
      this.#listeners[event] = []
    }
    this.#listeners[event].push(callback)
  }
  
  #off(event, callback) {
    if (!this.#listeners[event]) return
    
    if (callback) {
      this.#listeners[event] = this.#listeners[event].filter(cb => cb !== callback)
    } else {
      delete this.#listeners[event]
    }
  }
  
  #emit(event, data) {
    if (!this.#listeners[event]) return
    
    this.#listeners[event].forEach(callback => {
      callback(data)
    })
  }

  // Handle farm selection and prepare data for submission
  handleFarmSelected(data) {
    const { farmId, makeDefault } = data
    
    // Update hidden form input values before submission
    if (this.hasFormTarget) {
      const farmIdInput = this.formTarget.querySelector('input[name="farm_id"]')
      const makeDefaultInput = this.formTarget.querySelector('input[name="make_default"]')
      
      if (farmIdInput) farmIdInput.value = farmId
      if (makeDefaultInput) makeDefaultInput.value = makeDefault ? 'true' : ''
      
      // Submit the form
      this.formTarget.requestSubmit()
    }
  }

  // Toggle make default farm option
  toggleMakeDefault(event) {
    const isChecked = event.currentTarget.checked
    this.makeDefaultValue = isChecked
    
    // Emit event for the view controller
    this.#emit("makeDefaultToggled", { isChecked })
  }
}
