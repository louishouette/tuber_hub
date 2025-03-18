import { Controller } from "@hotwired/stimulus"
import { NotificationAPI, NotificationDOM } from "utilities/notification_utils"
import notificationEventBus from "utilities/event_bus"

export default class extends Controller {
  static targets = ["container"]

  connect() {
    this.setupEventListeners()
    this.setupDropdownListener()
    // Add resize listener for responsive positioning
    this.resizeHandler = this.handleResize.bind(this)
    window.addEventListener('resize', this.resizeHandler)
    
    // Initialize the notification counter when the page loads
    // This ensures the count is shown even when navigating between pages
    this.initializeCounter()
  }
  
  /**
   * Initialize the notification counter when the page loads
   */
  async initializeCounter() {
    try {
      const data = await NotificationAPI.getCount()
      NotificationDOM.updateCounter(data.count)
    } catch (error) {
      console.error('Error initializing notification counter:', error)
    }
  }

  disconnect() {
    this.removeDropdownListener()
    this.removeEventListeners()
    window.removeEventListener('resize', this.resizeHandler)
  }

  setupEventListeners() {
    // Listen for notification events from Action Cable
    this.notificationReceivedHandler = this.handleNotificationReceived.bind(this)
    notificationEventBus.on('notification:received', this.notificationReceivedHandler)
    
    // Listen for dismiss events
    this.notificationDismissedHandler = this.handleNotificationDismissed.bind(this)
    notificationEventBus.on('notification:dismissed', this.notificationDismissedHandler)
  }
  
  removeEventListeners() {
    notificationEventBus.off('notification:received', this.notificationReceivedHandler)
    notificationEventBus.off('notification:dismissed', this.notificationDismissedHandler)
  }
  
  handleNotificationReceived(data) {
    // When a new notification arrives via Action Cable, refresh the list if dropdown is open
    if (this.dropdown && !this.dropdown.classList.contains('hidden')) {
      this.loadNotifications()
    }
  }
  
  handleNotificationDismissed(data) {
    // Get the ID from data, handling both object formats
    const id = data?.id || (typeof data === 'string' ? data : null)
    
    if (id) {
      // Find and remove the notification from the UI if it exists
      const notificationItem = this.element.querySelector(`.notification-item[data-notification-id="${id}"]`)
      if (notificationItem) {
        NotificationDOM.animate(notificationItem, { 
          opacity: '0', 
          transform: 'translateX(10px)' 
        })
        
        setTimeout(() => {
          notificationItem.remove()
          
          // Check if we need to show empty state
          if (this.containerTarget.querySelectorAll('.notification-item').length === 0) {
            this.showEmptyState()
          }
        }, 300)
        
        // Decrement the notification counter to provide immediate feedback
        NotificationDOM.decrementCounter()
      }
    }
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
      // First check if we have any notifications to avoid loading at all
      const countData = await NotificationAPI.getCount()
      
      // Update the notification counter badge
      NotificationDOM.updateCounter(countData.count)
      
      // If there are notifications, fetch and display them
      const html = await NotificationAPI.getItems()
      if (!html) {
        return this.showEmptyState()
      }
      
      // Always update the container with the received HTML
      this.containerTarget.innerHTML = html
      
    } catch (error) {
      // Show empty state on error
      this.showEmptyState()
    }
  }
  
  async showEmptyState() {
    // Try to get the empty state from the server first
    const html = await NotificationAPI.getEmptyState()
    
    // If server request fails, use the local fallback
    this.containerTarget.innerHTML = html || NotificationDOM.getEmptyStateHTML()
  }

  async dismiss(event) {
    event.preventDefault()
    event.stopPropagation()
    
    const id = event.currentTarget.dataset.notificationId
    const notificationItem = event.currentTarget.closest(".notification-item")
    
    // Apply a fade-out effect before removing
    NotificationDOM.animate(notificationItem, { 
      opacity: '0', 
      transform: 'translateX(10px)' 
    })
    
    try {
      const success = await NotificationAPI.dismiss(id)
      
      if (!success) {
        throw new Error(`Failed to dismiss notification ${id}`)
      }
      
      // Get current count and decrement it
      const badge = NotificationDOM.getBadgeElement()
      let count = parseInt(badge?.textContent || '0')
      if (!isNaN(count) && count > 0) {
        count--
        NotificationDOM.updateCounter(count)
      }
      
      // Broadcast a dismiss event that other controllers can listen for
      NotificationDOM.broadcastDismissEvent(id)
      
      // Remove from UI after animation completes
      setTimeout(() => {
        notificationItem.remove()
        
        // Check if we need to show empty state
        if (this.containerTarget.querySelectorAll('.notification-item').length === 0) {
          this.loadNotifications()
        }
      }, 300)
    } catch (error) {
      // Restore opacity if there was an error
      NotificationDOM.animate(notificationItem, { 
        opacity: '1', 
        transform: 'translateX(0)' 
      })
    }
  }

  async markAllAsRead(event) {
    event.preventDefault()
    
    // Store target element and ensure it exists to prevent null reference errors
    const button = event.currentTarget
    if (!button) return
    
    // Don't allow multiple attempts at once
    if (button.dataset.processing === 'true') {
      return
    }

    // Store original text before modifying
    const originalButtonText = button.textContent || 'Mark all as read'
    
    try {
      // Flag to prevent multiple attempts
      button.dataset.processing = 'true'
      
      // Show loading visual feedback
      button.innerHTML = `<span class="inline-block animate-pulse">Processing...</span>`
      
      // Use the improved API method which now handles toast notifications internally
      // This avoids multiple toasts being shown since it controls the entire process
      const success = await NotificationAPI.markAllAsRead()
      
      if (success) {
        // Reload notifications to reflect changes
        this.loadNotifications()
      }
    } catch (error) {
      console.error('Error marking all as read:', error)
    } finally {
      // Always reset the button, whether successful or not
      setTimeout(() => {
        // Check if button still exists in DOM before updating
        if (button && button.parentNode) {
          button.innerHTML = originalButtonText
          delete button.dataset.processing
        }
      }, 500)
    }
  }
}
