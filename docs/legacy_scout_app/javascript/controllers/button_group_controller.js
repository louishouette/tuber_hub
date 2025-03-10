import { Controller } from "@hotwired/stimulus";

// Connects to data-controller="button-group"
export default class extends Controller {
  static targets = ["input"];

  connect() {
    // When connecting, ensure the selected input is visually active
    const value = this.inputTarget.value;
    if (value) {
      const selectedLabel = this.element.querySelector(`label[data-value="${value}"]`);
      if (selectedLabel) {
        this.updateSelection(selectedLabel);
      }
    }
  }

  select(event) {
    console.info("Select action triggered.", event.target);
    const selectedValue = event.target.dataset.value;
    
    // Immediately update visual state
    this.element.querySelectorAll('label').forEach(label => {
      const isSelected = label === event.target;
      label.classList.toggle('bg-blue-600', isSelected);
      label.classList.toggle('text-white', isSelected);
      label.classList.toggle('bg-gray-200', !isSelected);
    });

    // Update hidden input
    this.inputTarget.value = selectedValue;
    this.inputTarget.dispatchEvent(new Event('change', { bubbles: true }));
  }

  updateSelection(selectedLabel) {
    console.info("Updating selection to:", selectedLabel);
    this.element.querySelectorAll('label').forEach(label => {
      const isSelected = label === selectedLabel;
      label.classList.toggle('bg-blue-600', isSelected);
      label.classList.toggle('text-white', isSelected);
      label.classList.toggle('bg-gray-200', !isSelected);
    });
  }
}