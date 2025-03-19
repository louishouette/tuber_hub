import { Controller } from "@hotwired/stimulus"

// Farm switcher view controller - UI interactions
export default class extends Controller {
  static targets = ["dropdown", "currentFarmName", "makeDefaultCheckbox"]
  
  connect() {
    // Connect to business logic controller
    const businessController = this.application.getControllerForElementAndIdentifier(
      this.element,
      "farm-switcher"
    )
    
    if (businessController) {
      this.businessController = businessController
      businessController.emitter.on("makeDefaultToggled", this.updateMakeDefaultUI.bind(this))
    }
    
    // Set up Flowbite dropdown functionality
    if (typeof window.Flowbite !== 'undefined') {
      this.dropdown = new window.Flowbite.Dropdown(this.dropdownTarget, this.dropdownButtonTarget)
    }
  }
  
  disconnect() {
    if (this.businessController) {
      this.businessController.emitter.off("makeDefaultToggled")
    }
    
    // Clean up dropdown
    if (this.dropdown) {
      this.dropdown.destroy()
    }
  }
  
  // UI method to update the current farm display
  updateCurrentFarmDisplay(event) {
    const farmName = event.currentTarget.getAttribute('data-farm-name')
    const farmId = event.currentTarget.getAttribute('data-farm-id')
    const makeDefault = this.makeDefaultCheckboxTarget?.checked || false
    
    if (this.hasCurrentFarmNameTarget) {
      this.currentFarmNameTarget.textContent = farmName
    }
    
    // Communicate with business logic controller
    if (this.businessController) {
      this.businessController.emitter.emit("farmSelected", {
        farmId,
        makeDefault
      })
    }
    
    // Close dropdown
    if (this.dropdown) {
      this.dropdown.hide()
    }
  }
  
  // Update the UI based on make default checkbox
  updateMakeDefaultUI(data) {
    const { isChecked } = data
    
    // You can add visual feedback here if needed
    if (this.hasMakeDefaultInfoTarget) {
      this.makeDefaultInfoTarget.classList.toggle('hidden', !isChecked)
    }
  }
}
