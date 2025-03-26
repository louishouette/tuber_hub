import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="tabs"
export default class extends Controller {
  static targets = ["tab", "tabContent"]

  connect() {
    // Set the first tab as active by default if no tab is already active
    if (!this.hasActiveTab()) {
      this.activateTab(this.tabTargets[0])
    }
    
    // Also initialize when Turbo navigates to the page
    document.addEventListener('turbo:load', () => {
      if (!this.hasActiveTab()) {
        this.activateTab(this.tabTargets[0])
      }
    })
  }
  
  hasActiveTab() {
    return this.tabTargets.some(tab => {
      return tab.classList.contains('text-[#1C3835]') && 
             tab.classList.contains('border-[#1C3835]')
    })
  }
  
  switchTab(event) {
    event.preventDefault()
    
    // Get the clicked tab
    const clickedTab = event.currentTarget
    
    // Activate the clicked tab
    this.activateTab(clickedTab)
  }
  
  activateTab(tab) {
    // Remove active class from all tabs
    this.tabTargets.forEach(t => {
      t.classList.remove('text-[#1C3835]', 'border-[#1C3835]', 'dark:text-[#4ECCA3]', 'dark:border-[#4ECCA3]')
      t.classList.add('border-transparent', 'hover:text-[#1C3835]', 'hover:border-[#1C3835]', 'dark:hover:text-[#4ECCA3]')
      t.setAttribute('aria-selected', 'false')
    })
    
    // Add active class to the selected tab
    tab.classList.remove('border-transparent', 'hover:text-[#1C3835]', 'hover:border-[#1C3835]', 'dark:hover:text-[#4ECCA3]')
    tab.classList.add('text-[#1C3835]', 'border-[#1C3835]', 'dark:text-[#4ECCA3]', 'dark:border-[#4ECCA3]')
    tab.setAttribute('aria-selected', 'true')
    
    // Hide all tab content
    this.tabContentTargets.forEach(content => {
      content.classList.add('hidden')
    })
    
    // Show the selected tab content
    const tabId = tab.getAttribute('href').substring(1) // Remove the # from the href
    const tabContent = document.getElementById(tabId)
    if (tabContent) {
      tabContent.classList.remove('hidden')
    }
  }
}
