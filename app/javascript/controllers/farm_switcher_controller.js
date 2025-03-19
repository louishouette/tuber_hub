import { Controller } from "@hotwired/stimulus"
import { EventEmitter } from "../utilities/event_emitter"

// Farm switcher controller - Business logic
export default class extends Controller {
  static targets = ["dropdown"]
  static values = {
    currentFarm: String,
    makeDefault: Boolean
  }

  connect() {
    this.emitter = new EventEmitter()
    this.emitter.on("farmSelected", this.handleFarmSelected.bind(this))
  }

  disconnect() {
    this.emitter.off("farmSelected")
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
    this.emitter.emit("makeDefaultToggled", { isChecked })
  }
}
