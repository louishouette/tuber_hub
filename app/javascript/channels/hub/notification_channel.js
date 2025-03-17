import consumer from "../consumer"

const notificationChannel = consumer.subscriptions.create("Hub::NotificationChannel", {
  connected() {
    console.log('Connected to notification channel')
  },

  disconnected() {
    console.log('Disconnected from notification channel')
  },

  received(data) {
    // Handle new notification
    if (data.notification) {
      // Dispatch a custom event with the notification data
      const toastContainer = document.getElementById('toast-container')
      if (toastContainer) {
        const event = new CustomEvent('notification:toast', {
          detail: data.notification
        })
        toastContainer.dispatchEvent(event)
      }
      
      // Update the notification counter
      this.updateNotificationCount()
    }
  },
  
  async updateNotificationCount() {
    try {
      const response = await fetch('/hub/notifications/count')
      if (!response.ok) throw new Error('Failed to fetch count')
      
      const data = await response.json()
      const badge = document.querySelector('[data-notification-badge]')
      
      if (badge) {
        badge.textContent = data.count
        badge.classList.toggle('hidden', data.count === 0)
      }
    } catch (error) {
      console.error('Error updating notification count:', error)
    }
  }
})

export default notificationChannel
