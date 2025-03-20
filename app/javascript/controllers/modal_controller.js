import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["modal"]
  
  connect() {
    // Initialize modal functionality if needed
  }
  
  open(event) {
    // If called from an element with data-modal-id, find that modal
    const modalId = event.currentTarget.dataset.modalId
    let modalElement
    
    if (modalId) {
      modalElement = document.getElementById(modalId)
      if (!modalElement) {
        console.error(`Modal with id '${modalId}' not found`)
        return
      }
    } else if (this.hasModalTarget) {
      modalElement = this.modalTarget
    } else {
      console.error('No modal target found')
      return
    }
    
    // Show the modal
    modalElement.classList.remove("hidden")
    
    // Dispatch an event to notify other controllers that the modal has opened
    const openEvent = new CustomEvent("modal:opened", { 
      bubbles: true,
      detail: { modalId: modalElement.id } 
    })
    document.dispatchEvent(openEvent)
  }
  
  close() {
    if (this.hasModalTarget) {
      this.modalTarget.classList.add("hidden")
    } else {
      // Try to find the closest modal container and close it
      const modalContainer = this.element.closest('[data-controller="modal"]')
      if (modalContainer) {
        const modal = modalContainer.querySelector('[data-modal-target="modal"]')
        if (modal) {
          modal.classList.add("hidden")
        }
      }
    }
  }
}
