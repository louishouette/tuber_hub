import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["badge"]

  connect() {
    this.updateCount()
    this.bindEvents()
    
    // Set an interval to periodically check for new notifications (every 60 seconds)
    this.countInterval = setInterval(() => {
      this.updateCount()
    }, 60000) // 60 seconds
  }

  disconnect() {
    this.unbindEvents()
    if (this.countInterval) {
      clearInterval(this.countInterval)
    }
  }

  bindEvents() {
    this.receiveHandler = this.receive.bind(this)
    this.countChangedHandler = this.handleCountChanged.bind(this)
    this.element.addEventListener('notification:received', this.receiveHandler)
    this.element.addEventListener('notification:count-changed', this.countChangedHandler)
    console.log('Notification counter events bound')
  }

  unbindEvents() {
    this.element.removeEventListener('notification:received', this.receiveHandler)
    this.element.removeEventListener('notification:count-changed', this.countChangedHandler)
  }
  
  handleCountChanged() {
    console.log('Notification count change detected')
    this.updateCount()
  }

  receive(event) {
    if (event.detail && event.detail.count !== undefined) {
      this.updateBadge(event.detail.count)
    }
  }

  async updateCount() {
    try {
      console.log('Fetching notification count...')
      const response = await fetch("/hub/notifications/count")
      if (!response.ok) throw new Error("Failed to load notification count")
      
      const data = await response.json()
      console.log('Notification count received:', data.count)
      this.updateBadge(data.count)
    } catch (error) {
      console.error("Error fetching notification count:", error)
    }
  }

  updateBadge(count) {
    if (!this.hasBadgeTarget) {
      console.error('Badge target not found')
      return
    }
    
    const badge = this.badgeTarget
    const hadNotifications = !badge.classList.contains("hidden")
    const hasNotifications = count > 0
    
    console.log('Updating badge:', { count, hadNotifications, hasNotifications, badge })
    
    // Update the count text
    badge.textContent = count

    if (hasNotifications) {
      // Show badge with animation if it was previously hidden
      if (!hadNotifications) {
        console.log('Showing notification badge with count:', count)
        badge.classList.remove("hidden")
        this.animateBadge(badge)
      } else {
        console.log('Badge already visible, updating count to:', count)
      }
    } else {
      console.log('No notifications, hiding badge')
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
}
