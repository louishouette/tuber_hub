import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = {
    duration: { type: Number, default: 5000 } // 5 seconds by default
  }

  connect() {
    this.bindEvents()
    this.checkForNewNotifications()
  }

  disconnect() {
    this.unbindEvents()
  }

  bindEvents() {
    this.toastHandler = this.handleToastEvent.bind(this)
    this.element.addEventListener('notification:toast', this.toastHandler)
  }

  unbindEvents() {
    this.element.removeEventListener('notification:toast', this.toastHandler)
  }

  handleToastEvent(event) {
    if (event.detail) {
      this.showToast(event.detail)
    }
  }

  async checkForNewNotifications() {
    try {
      const response = await fetch("/hub/notifications/unread")
      if (!response.ok) throw new Error("Failed to fetch unread notifications")
      
      const notifications = await response.json()
      
      notifications.forEach(notification => {
        this.showToast(notification)
        this.markAsDisplayed(notification.id)
      })
    } catch (error) {
      console.error("Error checking for new notifications:", error)
    }
  }

  async showToast(notification) {
    try {
      // Fetch the toast partial
      const response = await fetch(`/hub/notifications/${notification.id}/toast`)
      if (!response.ok) throw new Error("Failed to load toast")
      
      const html = await response.text()
      
      // Insert the toast HTML
      const toastContainer = document.createElement('div')
      toastContainer.innerHTML = html
      const toast = toastContainer.firstElementChild
      
      this.element.appendChild(toast)
      
      // Set up auto-removal
      setTimeout(() => {
        toast.classList.add('animate-fade-out')
        setTimeout(() => {
          toast.remove()
        }, 300) // Match the fade out animation duration
      }, this.durationValue)
    } catch (error) {
      console.error("Error showing toast:", error)
    }
  }

  dismiss(event) {
    const toast = event.currentTarget.closest('.toast-notification')
    const id = toast.dataset.notificationId
    
    // Mark as dismissed in the database
    if (id) {
      fetch(`/hub/notifications/${id}/dismiss`, {
        method: "PATCH",
        headers: {
          "X-CSRF-Token": document.querySelector("meta[name='csrf-token']").content
        }
      }).catch(error => console.error("Error dismissing notification:", error))
    }
    
    // Remove from UI with animation
    toast.classList.add('animate-fade-out')
    setTimeout(() => {
      toast.remove()
    }, 300)
  }

  markAsDisplayed(id) {
    fetch(`/hub/notifications/${id}/displayed`, {
      method: "PATCH",
      headers: {
        "X-CSRF-Token": document.querySelector("meta[name='csrf-token']").content
      }
    }).catch(error => console.error("Error marking notification as displayed:", error))
  }
}
