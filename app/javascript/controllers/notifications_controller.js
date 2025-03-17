import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["container"]

  connect() {
    this.loadNotifications()
    this.setupDropdownListener()
    // Add resize listener for responsive positioning
    this.resizeHandler = this.handleResize.bind(this)
    window.addEventListener('resize', this.resizeHandler)
  }

  disconnect() {
    this.removeDropdownListener()
    window.removeEventListener('resize', this.resizeHandler)
  }

  handleResize() {
    // If dropdown is visible, update its position
    if (this.dropdown && !this.dropdown.classList.contains('hidden')) {
      this.positionDropdown()
    }
  }

  setupDropdownListener() {
    this.dropdownToggle = document.getElementById('notification-button')
    this.dropdown = document.getElementById('notification-dropdown')
    
    if (this.dropdownToggle && this.dropdown) {
      this.dropdownToggleHandler = () => {
        const isHidden = this.dropdown.classList.contains('hidden')
        if (isHidden) {
          // About to show, refresh notifications
          this.loadNotifications()
          
          // Position dropdown correctly
          this.positionDropdown()
        }
      }
      
      this.dropdownToggle.addEventListener('click', this.dropdownToggleHandler)
      
      // Add a document click listener to close dropdown when clicking outside
      this.documentClickHandler = (e) => {
        if (!this.dropdown.classList.contains('hidden') && 
            !this.element.contains(e.target) && 
            !this.dropdown.contains(e.target)) {
          // Close the dropdown using Flowbite's API if available
          const dropdownInstance = window._flowbite?.dropdowns?.getInstance(this.dropdown)
          if (dropdownInstance) {
            dropdownInstance.hide()
          } else {
            // Fallback if Flowbite instance not available
            this.dropdown.classList.add('hidden')
          }
        }
      }
      
      document.addEventListener('click', this.documentClickHandler)
    }
  }

  removeDropdownListener() {
    if (this.dropdownToggle && this.dropdownToggleHandler) {
      this.dropdownToggle.removeEventListener('click', this.dropdownToggleHandler)
    }
    
    if (this.documentClickHandler) {
      document.removeEventListener('click', this.documentClickHandler)
    }
  }

  positionDropdown() {
    if (!this.dropdown) return
    
    // Get the button's position for proper alignment
    const buttonRect = this.dropdownToggle.getBoundingClientRect()
    const headerHeight = document.querySelector('header')?.offsetHeight || 60
    
    // Only needed for mobile positioning
    if (window.innerWidth < 768) {
      // For mobile, position it fixed, centered near the top of the screen
      this.dropdown.classList.remove('md:absolute')
      this.dropdown.classList.add('fixed')
      this.dropdown.style.top = `${headerHeight + 5}px`  // Just below header
      this.dropdown.style.left = '50%'
      this.dropdown.style.right = 'auto'
      this.dropdown.style.transform = 'translateX(-50%)'
      this.dropdown.style.width = 'calc(100% - 32px)'
      this.dropdown.style.maxWidth = '400px'
    } else {
      // For desktop, position it right-aligned with the button
      this.dropdown.classList.add('md:absolute')
      this.dropdown.classList.remove('fixed')
      this.dropdown.style.top = ''
      this.dropdown.style.left = ''
      this.dropdown.style.right = '0'
      this.dropdown.style.transform = ''
      this.dropdown.style.width = ''
      this.dropdown.style.maxWidth = '400px'
    }
  }

  async loadNotifications() {
    try {
      console.log("Loading notifications...")
      // First check if we have any notifications to avoid loading at all
      const countResponse = await fetch("/hub/notifications/count")
      const countData = await countResponse.json()
      
      console.log("Notification count:", countData.count)
      
      // Update the notification counter badge
      this.element.dispatchEvent(new CustomEvent('notification:received', { 
        detail: { count: countData.count },
        bubbles: true
      }))
      
      // If there are notifications, fetch and display them
      const response = await fetch("/hub/notifications/items")
      if (!response.ok) {
        console.error("Failed to load notifications");
        return;
      }
      
      const html = await response.text()
      console.log("Received notification HTML:", html.substring(0, 100) + "...")
      
      // Always update the container with the received HTML
      this.containerTarget.innerHTML = html
      
    } catch (error) {
      console.error("Error loading notifications:", error)
      // Show empty state on error
      this.showEmptyState()
    }
  }
  
  showEmptyState() {
    // Directly render the empty state without a network request
    this.containerTarget.innerHTML = `
      <div class="py-8 px-4 text-center text-gray-500 dark:text-gray-400">
        <div class="flex flex-col items-center">
          <svg class="w-14 h-14 mb-3 opacity-60 text-gray-400 dark:text-gray-500" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M18.364 18.364A9 9 0 005.636 5.636m12.728 12.728A9 9 0 015.636 5.636m12.728 12.728L5.636 5.636"></path>
          </svg>
          <p class="font-medium text-base mb-1">No notifications</p>
          <p class="text-xs text-gray-400 dark:text-gray-500">You're all caught up!</p>
        </div>
      </div>
    `
  }

  async dismiss(event) {
    event.preventDefault()
    event.stopPropagation()
    
    const id = event.currentTarget.dataset.notificationId
    const notificationItem = event.currentTarget.closest(".notification-item")
    
    // Apply a fade-out effect before removing
    notificationItem.style.transition = 'opacity 0.3s, transform 0.3s'
    notificationItem.style.opacity = '0'
    notificationItem.style.transform = 'translateX(10px)'
    
    try {
      console.log(`📪 Dismissing notification ${id}...`)
      const response = await fetch(`/hub/notifications/${id}/dismiss`, {
        method: "PATCH",
        headers: {
          "X-CSRF-Token": document.querySelector("meta[name='csrf-token']").content,
          "Accept": "application/json"
        }
      })
      
      if (!response.ok) {
        throw new Error(`Server returned ${response.status}`)
      }
      
      // Get current count and decrement it
      const badge = document.querySelector('[data-notification-counter-target="badge"]')
      let count = parseInt(badge?.textContent || '0')
      if (!isNaN(count) && count > 0) {
        count--
        // Dispatch event to update counter
        document.dispatchEvent(new CustomEvent('notification:received', { 
          detail: { count },
          bubbles: true
        }))
      }
      
      // Broadcast a dismiss event that other controllers can listen for
      console.log(`📢 Broadcasting notification:dismissed event for ID ${id}`)
      document.dispatchEvent(new CustomEvent('notification:dismissed', {
        detail: { id },
        bubbles: true
      }))
      
      // Remove from UI after animation completes
      setTimeout(() => {
        notificationItem.remove()
        
        // Check if we need to show empty state
        if (this.containerTarget.querySelectorAll('.notification-item').length === 0) {
          this.loadNotifications()
        }
        
        console.log(`✅ Notification ${id} dismissed successfully`)
      }, 300)
    } catch (error) {
      console.error("Error dismissing notification:", error)
      // Restore opacity if there was an error
      notificationItem.style.opacity = '1'
      notificationItem.style.transform = 'translateX(0)'
    }
  }

  async markAllAsRead(event) {
    event.preventDefault()
    
    try {
      // Show loading visual feedback
      event.currentTarget.innerHTML = `<span class="inline-block animate-pulse">Processing...</span>`
      
      await fetch("/hub/notifications/mark_all_as_read", {
        method: "PATCH",
        headers: {
          "X-CSRF-Token": document.querySelector("meta[name='csrf-token']").content
        }
      })
      
      // Reset the unread counter to zero
      this.element.dispatchEvent(new CustomEvent('notification:received', { 
        detail: { count: 0 },
        bubbles: true
      }))
      
      // Reload notifications to reflect changes
      this.loadNotifications()
      
      // Reset button text
      setTimeout(() => {
        event.currentTarget.innerHTML = "Mark all as read"
      }, 500)
    } catch (error) {
      console.error("Error marking notifications as read:", error)
      event.currentTarget.innerHTML = "Mark all as read"
    }
  }
}
