import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["select", "container", "placeholder", "search", "dropdown", "option", "badge", "selected"]
  static classes = ["active", "selected"]

  connect() {
    // Initialize multiselect with a search input - only run once
    if (!this.element.querySelector('.multiselect-container')) {
      this.createMultiselect()
      this.updateSelectedOptions()
    }
  }

  createMultiselect() {
    // Create container
    const container = document.createElement('div')
    container.classList.add('multiselect-container', 'relative')
    this.element.appendChild(container)
    container.dataset.multiSelectTarget = 'container'

    // Create search input
    const searchContainer = document.createElement('div')
    searchContainer.classList.add('flex', 'flex-wrap', 'items-center', 'gap-1', 'bg-gray-50', 'border', 'border-gray-300', 'text-gray-900', 'text-sm', 'rounded-lg', 'focus-within:ring-primary-500', 'focus-within:border-primary-500', 'w-full', 'p-2')
    container.appendChild(searchContainer)

    // Create badge container for selected items
    const badgeContainer = document.createElement('div')
    badgeContainer.classList.add('flex', 'flex-wrap', 'gap-1', 'items-center', 'flex-grow')
    badgeContainer.dataset.multiSelectTarget = 'selected'
    searchContainer.appendChild(badgeContainer)

    // Add placeholder text
    const placeholder = document.createElement('span')
    placeholder.classList.add('text-gray-400')
    placeholder.textContent = this.selectTarget.dataset.placeholder || 'Select options...'
    placeholder.dataset.multiSelectTarget = 'placeholder'
    badgeContainer.appendChild(placeholder)

    // Create search input
    const searchInput = document.createElement('input')
    searchInput.type = 'text'
    searchInput.classList.add('text-sm', 'grow', 'min-w-[100px]', 'outline-none', 'border-none', 'bg-transparent')
    searchInput.placeholder = 'Type to search...'
    searchInput.dataset.multiSelectTarget = 'search'
    searchInput.addEventListener('input', this.filterOptions.bind(this))
    searchInput.addEventListener('focus', this.showDropdown.bind(this))
    searchInput.addEventListener('blur', () => setTimeout(() => this.hideDropdown(), 200))
    searchContainer.appendChild(searchInput)

    // Create dropdown
    const dropdown = document.createElement('div')
    dropdown.classList.add('absolute', 'z-50', 'w-full', 'bg-white', 'border', 'border-gray-300', 'rounded-lg', 'shadow-lg', 'mt-1', 'max-h-60', 'overflow-y-auto', 'hidden')
    dropdown.dataset.multiSelectTarget = 'dropdown'
    container.appendChild(dropdown)

    // Lazily add options only when dropdown is shown (performance optimization)
    this._optionsAdded = false 

    // Hide the original select but keep it in the form
    this.selectTarget.classList.add('hidden')
    this.selectTarget.setAttribute('aria-hidden', 'true')
  }

  addOptions() {
    // Add options to dropdown only if not already added
    if (this._optionsAdded) {
      // Update selected state of options
      this.updateOptionsSelectedState();
      return;
    }
    
    const dropdown = this.dropdownTarget;
    const fragment = document.createDocumentFragment();
    
    // Clear existing dropdown content
    while (dropdown.firstChild) {
      dropdown.removeChild(dropdown.firstChild);
    }
    
    // Get currently selected values
    const selectedValues = Array.from(this.selectTarget.selectedOptions).map(opt => opt.value);
    
    // Create options in a batch using fragment (faster than adding one by one)
    Array.from(this.selectTarget.options).forEach(option => {
      if (option.value === '') return // Skip placeholder options

      const optionElement = document.createElement('div')
      optionElement.classList.add('p-2', 'cursor-pointer', 'hover:bg-gray-100')
      
      // Mark as selected if it's in the selected values
      if (selectedValues.includes(option.value)) {
        optionElement.classList.add('bg-blue-50', 'text-blue-700', 'font-medium');
      }
      
      optionElement.dataset.multiSelectTarget = 'option'
      optionElement.dataset.value = option.value
      optionElement.dataset.text = option.text
      optionElement.textContent = option.text
      optionElement.addEventListener('click', () => this.toggleOption(option.value, option.text))
      fragment.appendChild(optionElement)
    })
    
    // Add all options to DOM in a single operation
    dropdown.appendChild(fragment);
    this._optionsAdded = true;
  }

  updateOptionsSelectedState() {
    if (!this._optionsAdded) return;
    
    // Get currently selected values
    const selectedValues = Array.from(this.selectTarget.selectedOptions).map(opt => opt.value);
    
    // Update each option's selected state
    this.optionTargets.forEach(option => {
      const value = option.dataset.value;
      
      if (selectedValues.includes(value)) {
        option.classList.add('bg-blue-50', 'text-blue-700', 'font-medium');
      } else {
        option.classList.remove('bg-blue-50', 'text-blue-700', 'font-medium');
      }
    });
  }

  filterOptions() {
    // Ensure options are added before filtering
    if (!this._optionsAdded) {
      this.addOptions();
    }
    
    const searchText = this.searchTarget.value.toLowerCase()
    
    this.optionTargets.forEach(option => {
      const optionText = option.dataset.text.toLowerCase()
      if (searchText === '' || optionText.includes(searchText)) {
        option.classList.remove('hidden')
      } else {
        option.classList.add('hidden')
      }
    })
  }

  showDropdown() {
    // Add options when dropdown is shown (lazy loading)
    this.addOptions();
    this.dropdownTarget.classList.remove('hidden');
  }

  toggleDropdown() {
    if (this.dropdownTarget.classList.contains('hidden')) {
      this.showDropdown();
    } else {
      this.hideDropdown();
    }
  }

  hideDropdown() {
    this.dropdownTarget.classList.add('hidden')
  }

  toggleOption(value, text) {
    const option = Array.from(this.selectTarget.options).find(opt => opt.value === value)
    
    if (option) {
      // Toggle selection
      option.selected = !option.selected
      
      // Update the UI
      this.updateSelectedOptions()
      this.updateOptionsSelectedState()
      
      // Dispatch change event on the select element
      const event = new Event('change', { bubbles: true })
      this.selectTarget.dispatchEvent(event)
    }
  }

  updateSelectedOptions() {
    // Clear existing badges
    const badgeContainer = this.selectedTarget
    
    // Get selected options
    const selectedOptions = Array.from(this.selectTarget.selectedOptions)
    
    // Remove all child nodes except the search input
    while (badgeContainer.firstChild) {
      badgeContainer.removeChild(badgeContainer.firstChild)
    }
    
    // Show placeholder if no options selected
    if (selectedOptions.length === 0) {
      const placeholder = document.createElement('span')
      placeholder.classList.add('text-gray-400')
      placeholder.textContent = this.selectTarget.dataset.placeholder || 'Select options...'
      badgeContainer.appendChild(placeholder)
    } else {
      // Create badges for selected options
      const fragment = document.createDocumentFragment();
      
      selectedOptions.forEach(option => {
        const badge = document.createElement('span')
        badge.classList.add('bg-primary-100', 'text-primary-800', 'text-xs', 'font-medium', 'px-2.5', 'py-0.5', 'rounded', 'flex', 'items-center')
        badge.dataset.multiSelectTarget = 'badge'
        
        const text = document.createTextNode(option.text)
        badge.appendChild(text)
        
        const removeBtn = document.createElement('button')
        removeBtn.innerHTML = '&times;'
        removeBtn.classList.add('ml-1.5', 'text-xs', 'font-bold')
        removeBtn.addEventListener('click', (e) => {
          e.stopPropagation()
          this.toggleOption(option.value, option.text)
        })
        
        badge.appendChild(removeBtn)
        fragment.appendChild(badge)
      })
      
      badgeContainer.appendChild(fragment)
    }
  }

  disconnect() {
    // Cleanup any event listeners if needed
  }
}
