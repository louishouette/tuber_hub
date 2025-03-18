import { Controller } from "@hotwired/stimulus"
import { NotificationAPI, NotificationDOM } from "utilities/notification_utils"
import notificationEventBus from "utilities/event_bus"

export default class extends Controller {
  static targets = ["container", "item"]

  connect() {
    this.setupEventListeners()
  }

  disconnect() {
    this.removeEventListeners()
  }

  setupEventListeners() {
    // Listen for notification events via event bus to ensure consistent behavior
    this.dismissHandler = this.handleDismissed.bind(this)
    this.newNotificationHandler = this.handleNewNotification.bind(this)
    
    // Use event bus instead of document events to avoid duplicate handling
    notificationEventBus.on('notification:dismissed', this.dismissHandler)
    notificationEventBus.on('notification:received', this.newNotificationHandler)
  }

  removeEventListeners() {
    notificationEventBus.off('notification:dismissed', this.dismissHandler)
    notificationEventBus.off('notification:received', this.newNotificationHandler)
  }
  
  handleNewNotification(event) {
    // Reload the notifications list to include the new notification
    this.reloadNotificationsList()
  }

  handleDismissed(event) {
    // Fix destructuring to handle both formats of event data
    // Sometimes event.detail is an object with id, sometimes the event is already the data object
    const id = event.detail?.id || event.id
    
    if (!id) {
      console.warn('[NotificationList] Received dismiss event without ID')
      return
    }
    
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
          item.remove()
          
          // Update empty state if needed
          if (this.element.querySelectorAll('.notification-item').length === 0) {
            this.showEmptyState()
          }
        }, 300)
      })
    }
  }
  
  async showEmptyState() {
    try {
      const html = await NotificationAPI.getEmptyState()
      
      // Only update if we still have no items (in case new notifications arrived)
      if (this.element.querySelectorAll('.notification-item').length === 0 && html) {
        this.containerTarget.innerHTML = html
      }
    } catch (error) {
      // Silently handle errors
      this.containerTarget.innerHTML = NotificationDOM.getEmptyStateHTML()
    }
  }
  
  // Reload the notifications list without creating additional AJAX requests
  async reloadNotificationsList() {
    try {
      // Only fetch updated notification items when needed
      // This avoids creating too many requests
      const itemsHtml = await NotificationAPI.getItems()
      
      if (itemsHtml) {
        // Update the items container
        this.containerTarget.innerHTML = itemsHtml
      } else {
        this.showEmptyState()
      }
    } catch (error) {
      // Silently handle errors
      this.showEmptyState()
    }
  }
  
  // Update stats from Action Cable data instead of separate AJAX request
  updateNotificationStats(data) {
    if (!data) return
    
    // Update the count displays in the UI if they exist
    const unreadCountEl = document.querySelector('.p-4.bg-white.rounded-lg.shadow:nth-child(1) .text-xl.font-bold')
    const totalCountEl = document.querySelector('.p-4.bg-white.rounded-lg.shadow:nth-child(2) .text-xl.font-bold')
    const readRateEl = document.querySelector('.p-4.bg-white.rounded-lg.shadow:nth-child(3) .text-xl.font-bold')
    
    const unreadCount = data.unread_count || data.count || 0
    const totalCount = data.total_count || 0
    const readRate = data.read_rate || 0
    
    if (unreadCountEl) unreadCountEl.textContent = unreadCount
    if (totalCountEl) totalCountEl.textContent = totalCount
    if (readRateEl) readRateEl.textContent = `${readRate}%`
  }
  
  // Add a method that can be called from dismiss buttons on notification items
  async dismiss(event) {
    event.preventDefault()
    event.stopPropagation()
    
    const id = event.currentTarget.dataset.notificationId
    const notificationItem = event.currentTarget.closest('.notification-item')
    
    // Apply fade-out animation
    NotificationDOM.animate(notificationItem, {
      opacity: '0',
      transform: 'translateX(10px)'
    })
    
    try {
      // Instead of calling API directly, use the NotificationChannel if available
      let success = false
      const notificationChannel = window.notificationChannel
      
      if (notificationChannel) {
        // Use Action Cable to dismiss the notification
        success = notificationChannel.safePerform('dismiss', { id })
      } else {
        // Fallback to REST API if Action Cable not available
        success = await NotificationAPI.dismiss(id)
      }
      
      if (!success) {
        throw new Error(`Failed to dismiss notification ${id}`)
      }
      
      // Remove after animation completes
      // Note: We don't need to broadcast an event anymore since the server will do it
      setTimeout(() => {
        notificationItem.remove()
        
        // Check empty state
        if (this.element.querySelectorAll('.notification-item').length === 0) {
          this.showEmptyState()
        }
      }, 300)
    } catch (error) {
      // Silently handle error but reset animation
      NotificationDOM.animate(notificationItem, {
        opacity: '1',
        transform: 'translateX(0)'
      })
    }
  }
}
