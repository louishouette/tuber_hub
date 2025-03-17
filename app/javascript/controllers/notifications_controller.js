import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["container"]

  connect() {
    this.loadNotifications()
  }

  async loadNotifications() {
    try {
      const response = await fetch("/hub/notifications/items")
      if (!response.ok) throw new Error("Failed to load notifications")
      
      const html = await response.text()
      this.containerTarget.innerHTML = html
    } catch (error) {
      console.error("Error loading notifications:", error)
      this.containerTarget.innerHTML = '<div class="py-4 px-4 text-center text-red-500">Failed to load notifications</div>'
    }
  }

  async dismiss(event) {
    const id = event.currentTarget.dataset.notificationId
    
    try {
      await fetch(`/hub/notifications/${id}/dismiss`, {
        method: "PATCH",
        headers: {
          "X-CSRF-Token": document.querySelector("meta[name='csrf-token']").content
        }
      })
      
      // Remove from UI
      event.currentTarget.closest(".notification-item").remove()
      
      // Check if we need to show empty state
      if (this.containerTarget.querySelectorAll('.notification-item').length === 0) {
        this.loadNotifications()
      }
    } catch (error) {
      console.error("Error dismissing notification:", error)
    }
  }

  async markAllAsRead(event) {
    event.preventDefault()
    
    try {
      await fetch("/hub/notifications/mark_all_as_read", {
        method: "PATCH",
        headers: {
          "X-CSRF-Token": document.querySelector("meta[name='csrf-token']").content
        }
      })
      
      this.loadNotifications()
    } catch (error) {
      console.error("Error marking notifications as read:", error)
    }
  }
}
