import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["select", "container"];

  connect() {
    // Set initial state when the controller connects
    // This ensures filtering works immediately on page load
    this.filter();
  }

  filter() {
    // Skip if select target is missing
    if (!this.hasSelectTarget) {
      return;
    }
    
    const selectedNamespace = this.selectTarget.value;
    
    this.containerTargets.forEach(container => {
      const containerNamespace = container.dataset.namespace;
      
      if (selectedNamespace === "all" || containerNamespace === selectedNamespace) {
        container.style.display = "block";
      } else {
        container.style.display = "none";
      }
    });
  }
}
