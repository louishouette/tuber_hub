import { Controller } from "@hotwired/stimulus"
import { NotificationDOM } from "utilities/notification_utils"
import notificationEventBus from "utilities/event_bus"

export default class extends Controller {
  static targets = ["badge"]

  connect() {
    this.bindEvents()
  }

  disconnect() {
    this.unbindEvents()
  }

  bindEvents() {
    // DOM events for backward compatibility
    this.receiveHandler = this.receive.bind(this)
    this.element.addEventListener('notification:received', this.receiveHandler)
    
    // EventBus for modern components
    this.eventBusNotificationHandler = this.handleNotificationEvent.bind(this)
    notificationEventBus.on('notification:received', this.eventBusNotificationHandler)
    
    // Listen for unread count updates from Action Cable
    this.countUpdatedHandler = this.handleCountUpdated.bind(this)
    notificationEventBus.on('notification:count-updated', this.countUpdatedHandler)
  }

  unbindEvents() {
    // Clean up DOM event listeners
    this.element.removeEventListener('notification:received', this.receiveHandler)
    
    // Clean up EventBus listeners
    notificationEventBus.off('notification:received', this.eventBusNotificationHandler)
    notificationEventBus.off('notification:count-updated', this.countUpdatedHandler)
  }
  
  handleCountUpdated(data) {
    // Only update the UI using data from the event - no AJAX calls
    if (data && data.count !== undefined) {
      this.updateBadge(data.count)
    }
  }
  
  handleNotificationEvent(data) {
    // Handle notification:received events from Action Cable
    if (data && data.count !== undefined) {
      this.updateBadge(data.count)
    } else if (data && data.notification && data.notification.unread_count !== undefined) {
      this.updateBadge(data.notification.unread_count)
    }
  }

  receive(event) {
    if (event.detail && event.detail.count !== undefined) {
      this.updateBadge(event.detail.count)
    }
  }

  updateBadge(count) {
    if (!this.hasBadgeTarget) {
      return
    }
    
    const badge = this.badgeTarget
    const hadNotifications = !badge.classList.contains("hidden")
    const hasNotifications = count > 0
    
    // Update the count text
    badge.textContent = count

    if (hasNotifications) {
      // Show badge with animation if it was previously hidden
      if (!hadNotifications) {
        badge.classList.remove("hidden")
        this.animateBadge(badge)
      } else if (parseInt(badge.textContent) !== count) {
        // If count changed but both old and new are > 0, do a subtle animation
        this.pulseAnimation(badge)
      }
    } else {
      badge.classList.add("hidden")
    }
  }
  
  animateBadge(badge) {
    // Add a brief animation to draw attention to new notifications
    badge.animate([
      { transform: 'scale(0)', opacity: 0 },
      { transform: 'scale(1.2)', opacity: 1 },
      { transform: 'scale(1)', opacity: 1 }
    ], {
      duration: 300,
      easing: 'ease-out'
    })
  }
  
  pulseAnimation(badge) {
    // Subtle pulse animation for when count changes but badge was already visible
    badge.animate([
      { transform: 'scale(1)', backgroundColor: 'var(--badge-bg, #ef4444)' },
      { transform: 'scale(1.1)', backgroundColor: '#f87171' },
      { transform: 'scale(1)', backgroundColor: 'var(--badge-bg, #ef4444)' }
    ], {
      duration: 300,
      easing: 'ease-in-out'
    })
  }
}
