import consumer from "channels/consumer"

consumer.subscriptions.create("NotificationChannel", {
  connected() {
    // Called when the subscription is ready for use on the server
    console.log('Connected to NotificationChannel')
  },

  disconnected() {
    // Called when the subscription has been terminated by the server
    console.log('Disconnected from NotificationChannel')
  },

  received(data) {
    // Called when there's incoming data on the websocket for this channel
    console.log('Received notification:', data)
    
    // Update notification counter if available
    const counterController = document.querySelector('[data-controller="notification-counter"]')
    if (counterController) {
      const event = new CustomEvent('notification:received', { detail: data })
      counterController.dispatchEvent(event)
    }
    
    // Show toast notification if available
    const toastContainer = document.querySelector('#toast-container')
    if (toastContainer) {
      const event = new CustomEvent('notification:toast', { detail: data })
      toastContainer.dispatchEvent(event)
    }
  }
});
