import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["container", "item"]

  connect() {
    console.log('Notification list controller connected')
    this.setupEventListeners()
  }

  disconnect() {
    this.removeEventListeners()
  }

  setupEventListeners() {
    // Listen for notification dismissed events
    this.dismissHandler = this.handleDismissed.bind(this)
    document.addEventListener('notification:dismissed', this.dismissHandler)
  }

  removeEventListeners() {
    document.removeEventListener('notification:dismissed', this.dismissHandler)
  }

  handleDismissed(event) {
    console.log('⚡ Notification list received dismiss event:', event.detail)
    const { id } = event.detail
    
    // Find notification items with this ID and animate their removal
    const itemsToRemove = this.element.querySelectorAll(`.notification-item[data-notification-id="${id}"]`)
    
    if (itemsToRemove.length > 0) {
      itemsToRemove.forEach(item => {
        // Apply fade-out animation
        item.style.transition = 'opacity 0.3s, transform 0.3s'
        item.style.opacity = '0'
        item.style.transform = 'translateX(10px)'
        
        // Remove after animation completes
        setTimeout(() => {
          console.log(`🗑️ Removing notification item #${id} from list`)
          item.remove()
          
          // Update empty state if needed
          if (this.element.querySelectorAll('.notification-item').length === 0) {
            console.log('📭 No notifications left, showing empty state...')
            this.showEmptyState()
          }
        }, 300)
      })
    }
  }
  
  async showEmptyState() {
    try {
      const response = await fetch('/hub/notifications/empty_state')
      const html = await response.text()
      
      // Only update if we still have no items (in case new notifications arrived)
      if (this.element.querySelectorAll('.notification-item').length === 0) {
        this.element.innerHTML = html
      }
    } catch (error) {
      console.error('Error loading empty state:', error)
    }
  }
  
  // Add a method that can be called from dismiss buttons on notification items
  async dismiss(event) {
    event.preventDefault()
    event.stopPropagation()
    
    const id = event.currentTarget.dataset.notificationId
    const notificationItem = event.currentTarget.closest('.notification-item')
    
    try {
      console.log(`📪 Dismissing notification ${id} from list...`)
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
      
      // Apply a fade-out effect
      notificationItem.style.transition = 'opacity 0.3s, transform 0.3s'
      notificationItem.style.opacity = '0'
      notificationItem.style.transform = 'translateX(10px)'
      
      // Broadcast a dismiss event for other controllers
      document.dispatchEvent(new CustomEvent('notification:dismissed', {
        detail: { id },
        bubbles: true
      }))
      
      // Remove after animation completes
      setTimeout(() => {
        notificationItem.remove()
        
        // Check empty state
        if (this.element.querySelectorAll('.notification-item').length === 0) {
          this.showEmptyState()
        }
      }, 300)
    } catch (error) {
      console.error('Error dismissing notification:', error)
      // Reset animation if there was an error
      notificationItem.style.opacity = '1'
      notificationItem.style.transform = 'translateX(0)'
    }
  }
}
