import { Controller } from "@hotwired/stimulus"
// Flowbite is loaded globally via CDN

// Connects to data-controller="notifications"
export default class extends Controller {
  static targets = ['dropdown', 'count', 'list']
  static values = {}

  connect() {}
  
  markAllAsRead() {
    const unreadNotifications = this.listTarget.querySelectorAll('[data-notification-unread]')
    unreadNotifications.forEach(notification => {
      notification.removeAttribute('data-notification-unread')
      notification.classList.remove('bg-gray-50', 'dark:bg-gray-700')
    })
    
    this.updateCount(0)
  }

  updateCount(count) {
    if (this.hasCountTarget) {
      this.countTarget.textContent = count
      this.countTarget.classList.toggle('hidden', count === 0)
    }
  }

  // Called from Turbo Stream
  addNotification(event) {
    const notification = event.detail[0]
    if (notification) {
      this.listTarget.insertAdjacentHTML('afterbegin', notification)
      const currentCount = parseInt(this.countTarget.textContent || '0')
      this.updateCount(currentCount + 1)
    }
  }
}
