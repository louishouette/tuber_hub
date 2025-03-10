import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["field", "direction", "orchardTab", "sortButton"]
  
  connect() {
    console.log("Sort controller connected")
    
    // Initialize sort state if present in form fields
    if (this.hasFieldTarget && this.fieldTarget.value) {
      const field = this.fieldTarget.value
      const direction = this.directionTarget.value
      console.log(`Initial sort state: ${field} ${direction}`)
      
      // Update buttons to reflect current sort state
      this.updateSortButtons(field, direction)
    }
  }

  sort(event) {
    event.preventDefault()
    
    const button = event.currentTarget
    const field = button.dataset.sortField
    const currentDirection = button.dataset.currentDirection
    
    // Determine new direction
    let newDirection
    if (currentDirection === 'none') {
      // First click on this field - use desc by default (highest values first)
      newDirection = 'desc'
    } else if (currentDirection === 'desc') {
      // Toggle from desc to asc
      newDirection = 'asc'
    } else {
      // Toggle from asc to desc
      newDirection = 'desc'
    }

    console.log(`Sorting by ${field} in ${newDirection} direction`)
    
    if (this.hasFieldTarget) {
      // Update hidden form fields (for page refresh state)
      this.fieldTarget.value = field
      this.directionTarget.value = newDirection
    }
    
    // Update sort button appearances
    this.updateSortButtons(field, newDirection)
    
    // Perform the client-side sort
    this.sortParcelCards(field, newDirection)
  }
  
  updateSortButtons(activeField, activeDirection) {
    // Update all sort buttons to reflect the current sort state
    this.sortButtonTargets.forEach(button => {
      const buttonField = button.dataset.sortField
      const isActive = buttonField === activeField
      
      // Update the button's appearance
      if (isActive) {
        button.classList.add('bg-gray-200')
        button.classList.remove('text-gray-500', 'bg-white', 'border', 'border-gray-300')
        button.dataset.currentDirection = activeDirection
        
        // Update the arrow icon
        const svg = button.querySelector('svg path')
        if (svg) {
          if (activeDirection === 'desc') {
            svg.setAttribute('d', 'M19 9l-7 7-7-7')
          } else {
            svg.setAttribute('d', 'M5 15l7-7 7 7')
          }
        }
      } else {
        button.classList.remove('bg-gray-200')
        button.classList.add('text-gray-500', 'bg-white', 'border', 'border-gray-300')
        button.dataset.currentDirection = 'none'
        
        // Reset the arrow icon
        const svg = button.querySelector('svg path')
        if (svg) {
          svg.setAttribute('d', 'M5 15l7-7 7 7')
        }
      }
    })
  }

  sortParcelCards(field, direction) {
    // Find the parcel cards container
    const container = this.hasOrchardTabTarget ? this.orchardTabTarget : this.findParcelContainer()
    if (!container) {
      console.error("No parcel container found!")
      return
    }
    
    console.log("Container:", container)
    
    // Get all parcel cards
    const parcelCards = Array.from(container.children)
    console.log(`Found ${parcelCards.length} parcel cards to sort`)
    
    if (parcelCards.length === 0) {
      console.warn("No parcel cards found to sort")
      return
    }
    
    // Log sample data for debugging
    if (parcelCards.length > 0) {
      console.log("Sample card:", parcelCards[0])
      console.log("Sample card dataset:", parcelCards[0].dataset)
    }
    
    // Sort the cards
    parcelCards.sort((a, b) => {
      let valueA, valueB
      
      // Different handling based on field type
      if (field === 'name') {
        // For name, extract from the h3 element
        const nameElementA = a.querySelector('h3')
        const nameElementB = b.querySelector('h3')
        valueA = nameElementA ? nameElementA.textContent.trim() : ''
        valueB = nameElementB ? nameElementB.textContent.trim() : ''
        return direction === 'asc' ? 
          valueA.localeCompare(valueB) : 
          valueB.localeCompare(valueA)
      } 
      else if (field === 'planted_at') {
        // For dates, parse as Date objects
        const dateA = a.dataset.plantedAt ? new Date(a.dataset.plantedAt) : new Date(0)
        const dateB = b.dataset.plantedAt ? new Date(b.dataset.plantedAt) : new Date(0)
        return direction === 'asc' ? dateA - dateB : dateB - dateA
      }
      else {
        // For numeric fields, use the kebab-case data attribute
        const kebabField = field.replace(/_/g, '-')
        valueA = parseFloat(a.dataset[this.camelCase(kebabField)] || 0)
        valueB = parseFloat(b.dataset[this.camelCase(kebabField)] || 0)
        return direction === 'asc' ? valueA - valueB : valueB - valueA
      }
    })
    
    // Clear the container and append sorted cards
    while (container.firstChild) {
      container.removeChild(container.firstChild)
    }
    
    // Re-append all cards in the new order
    parcelCards.forEach(card => container.appendChild(card))
    console.log("Sorting complete")
  }
  
  // Find the parcel cards container when the target is not available
  findParcelContainer() {
    // Try to find the grid container that holds all parcel cards
    const gridContainer = document.querySelector('.grid.gap-4')
    if (gridContainer) {
      console.log("Found grid container for parcels")
      return gridContainer
    }
    
    // Fallback to any container that has parcel cards
    return document.querySelector('div:has([data-planted-at])')
  }
  
  // Helper to convert kebab-case to camelCase for dataset properties
  camelCase(input) {
    return input.replace(/-([a-z])/g, function (g) { return g[1].toUpperCase(); });
  }
}
