import consumer from "channels/consumer"

// Safely create notification channel
let notificationChannel = null;

try {
  // Check if consumer is available
  if (consumer) {
    console.log('Creating notification channel subscription...');
    notificationChannel = consumer.subscriptions.create("Hub::NotificationChannel", {
      connected() {
        console.log('Successfully connected to Hub::NotificationChannel')
      },

      disconnected() {
        console.log('Disconnected from notification channel')
      },

      received(data) {
        console.log('✅ Notification received from channel:', data)
        // Handle new notification
        if (data.notification) {
          console.log('Processing notification data:', data.notification)
          
          // First, update the counter
          this.updateNotificationCount()

          // Then display the toast notification
          this.showToastNotification(data.notification)
          
          // Dispatch a custom event for other components to use
          console.log('Dispatching notification:received event')
          document.dispatchEvent(new CustomEvent('notification:received', { 
            detail: { 
              count: data.notification.unread_count || 1,
              notification: data.notification 
            },
            bubbles: true
          }))
        } else {
          console.warn('Received data without notification object:', data)
        }
      },

      // Show a toast notification
      showToastNotification(notification) {
        console.log('Preparing to show toast notification')
        
        // First, try to find the toast container by ID
        let toastContainer = document.getElementById('toast-container')
        
        // If not found by ID, try to find it by data attribute
        if (!toastContainer) {
          toastContainer = document.querySelector('[data-toast-target="container"]')
        }
        
        // If not found by data attribute, try to find it by controller
        if (!toastContainer) {
          toastContainer = document.querySelector('[data-controller="toast"]')
        }
        
        if (toastContainer) {
          console.log('Toast container found, dispatching notification:toast event', notification)
          
          // Create and dispatch the event
          const event = new CustomEvent('notification:toast', {
            detail: notification,
            bubbles: true // Make sure event bubbles up through the DOM
          })
          
          // Dispatch both to document and directly to container for maximum compatibility
          document.dispatchEvent(event)
          toastContainer.dispatchEvent(event)
          console.log('Toast notification event dispatched')
        } else {
          console.error('Toast container not found, notification will not be shown as toast')
        }
      },

      // Update the notification count in the UI
      updateNotificationCount() {
        console.log('Fetching updated notification count...')
        
        fetch('/hub/notifications/count')
          .then(response => {
            if (!response.ok) {
              throw new Error(`Server returned ${response.status}: ${response.statusText}`)
            }
            return response.json()
          })
          .then(data => {
            console.log('Notification count updated:', data)
            
            // Try multiple selectors to find notification badge
            let badge = document.querySelector('[data-notification-badge]')
            
            if (!badge) {
              badge = document.querySelector('[data-notification-counter-target="badge"]')
            }
            
            if (badge) {
              console.log('Found notification badge, updating to:', data.count)
              badge.textContent = data.count
              badge.classList.toggle('hidden', data.count === 0)
              
              // Also dispatch an event that other components can listen for
              const countEvent = new CustomEvent('notification:count-changed', {
                detail: { count: data.count },
                bubbles: true
              })
              document.dispatchEvent(countEvent)
            } else {
              console.warn('Notification badge not found in DOM')
            }
          })
          .catch(error => console.error('Error updating notification count:', error))
      }
    })
  }
} catch (error) {
  console.error('Error connecting to notification channel:', error)
}

export default notificationChannel
