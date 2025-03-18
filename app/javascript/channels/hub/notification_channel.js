import consumer from "channels/consumer"
import { NotificationAPI, NotificationDOM } from "utilities/notification_utils"
import notificationEventBus from "utilities/event_bus"
import { NotificationType } from "utilities/notification_types"

/**
 * Notification Channel for real-time notifications via Solid Cable
 * Handles receiving notifications, displaying toasts, and updating counters
 */

// Log channel connection status for debugging
const DEBUG = false;
const log = (...args) => DEBUG && console.log('[NotificationChannel]', ...args);

// Safely create notification channel
// Export as a global for components that need direct access
let notificationChannel = null;

try {
  // Check if consumer is available
  if (consumer) {
    notificationChannel = consumer.subscriptions.create("Hub::NotificationChannel", {
      connected() {
        log('Connected to notification channel')
        this.sendPendingActions()
      },

      disconnected() {
        log('Disconnected from notification channel')
      },
      
      // Store pending actions when disconnected
      pendingActions: [],
      
      // Send any pending actions when we reconnect
      sendPendingActions() {
        if (this.pendingActions.length > 0) {
          log('Sending pending actions:', this.pendingActions.length)
          
          this.pendingActions.forEach(action => {
            this.perform(action.name, action.data)
          })
          
          this.pendingActions = []
        }
      },
      
      // Safely perform an action or queue it if disconnected
      safePerform(actionName, data = {}) {
        // Check if connection is in OPEN state (1)
        if (this.consumer && this.consumer.connection && this.consumer.connection.webSocket && this.consumer.connection.webSocket.readyState === 1) {
          return this.perform(actionName, data)
        } else {
          log('Connection not available, queuing action:', actionName)
          this.pendingActions.push({ name: actionName, data })
          return false
        }
      },
      
      // Request the current unread count from the server
      // This is useful when we need to refresh the count without polling
      requestCount() {
        log('Requesting unread count from server')
        return this.safePerform('request_count')
      },

      received(data) {
        log('Received message:', data)
        
        // Skip if no data received
        if (!data) {
          console.error('[NotificationChannel] Received empty data')
          return
        }
        
        // Handle different types of messages from the server
        if (data.type || data.action) {
          // Get the message type (support both new type and legacy action)
          const messageType = data.type || data.action
          
          switch (messageType) {
            case 'notification_dismissed':
              this.handleNotificationDismissed(data)
              break
              
            case 'unread_count_updated':
              this.handleUnreadCountUpdated(data)
              break
              
            case 'all_notifications_read':
              // All notifications were marked as read
              notificationEventBus.emit('notification:all-read')
              this.handleUnreadCountUpdated({ count: 0 })
              break
              
            case 'ping':
              // Server checking if we're alive
              this.safePerform('pong')
              break
              
            default:
              log('Unknown message type received:', messageType)
          }
        }
        // Handle notification object (most common case)
        else if (data.notification) {
          // First, update the counter if unread_count is provided
          if (data.notification.unread_count !== undefined) {
            this.handleUnreadCountUpdated({ count: data.notification.unread_count })
          } else {
            // Otherwise fetch the latest count from the server
            this.updateNotificationCount()
          }

          // Then display the toast notification if requested
          const showToast = data.notification.show_toast === true
          if (showToast) {
            this.showToastNotification(data.notification)
          }
          
          // Use event bus to notify the application of the new notification
          notificationEventBus.emit('notification:received', {
            count: data.notification.unread_count || 1,
            notification: data.notification
          })
        } else {
          log('Received unrecognized message format:', data)
        }
      },
      
      // Handle notification dismissed action
      handleNotificationDismissed(data) {
        if (data.id) {
          log('Notification dismissed:', data.id)
          // Emit event with the correct data structure
          notificationEventBus.emit('notification:dismissed', { id: data.id })
          
          // Use the DOM utility to broadcast the event and update counter
          NotificationDOM.broadcastDismissEvent(data.id)
          
          // If the count was provided in the message, update it directly
          if (data.count !== undefined) {
            this.handleUnreadCountUpdated({ count: data.count })
          } else {
            // Otherwise fetch the latest count after a brief delay
            // to allow the server time to process the dismissal
            setTimeout(() => this.updateNotificationCount(), 300)
          }
        }
      },
      
      // Handle unread count updated action
      handleUnreadCountUpdated(data) {
        if (data.count !== undefined) {
          log('Unread count updated:', data.count)
          // Use event bus to notify all components of count change
          notificationEventBus.emit('notification:count-updated', { count: data.count })
          
          // Also update DOM directly for older components
          NotificationDOM.updateCounter(data.count)
        }
      },
      
      // Mark notification as read
      markAsRead(notificationId) {
        log('Marking notification as read:', notificationId)
        return this.safePerform('mark_as_read', { id: notificationId })
      },
      
      // Dismiss a notification
      dismissNotification(notificationId) {
        log('Dismissing notification:', notificationId)
        return this.safePerform('dismiss', { id: notificationId })  
      },
      
      // Mark notification as displayed
      markAsDisplayed(notificationId) {
        log('Marking notification as displayed:', notificationId)
        return this.safePerform('mark_as_displayed', { id: notificationId })
      },

      // Show a toast notification
      showToastNotification(notification) {
        // First, try to find the toast container by ID
        let toastContainer = document.getElementById('toast-container')
        
        // If not found by ID, try to find it by data attribute
        if (!toastContainer) {
          toastContainer = document.querySelector('[data-toasts-target="container"]')
        }
        
        // If not found by data attribute, try to find it by controller
        if (!toastContainer) {
          toastContainer = document.querySelector('[data-controller="toasts"]')
        }
        
        if (toastContainer) {
          // Make sure notification has required fields for toast
          const toastNotification = {
            id: notification.id,
            message: notification.message,
            notification_type: notification.notification_type,
            created_at: notification.created_at,
            url: notification.url
          }
          
          // Create and dispatch the event
          const event = new CustomEvent('notification:toast', {
            detail: toastNotification,
            bubbles: true // Make sure event bubbles up through the DOM
          })
          
          // Dispatch both to document and directly to container for maximum compatibility
          document.dispatchEvent(event)
          toastContainer.dispatchEvent(event)
        }
      },

      // Update the notification count in the UI
      async updateNotificationCount() {
        try {
          const data = await NotificationAPI.getCount()
          
          // Use NotificationDOM utility to update the counter
          NotificationDOM.updateCounter(data.count)
          
          // We no longer emit the event here to prevent loops
          // Direct DOM updates are preferred - components that need this data
          // should listen to the Action Cable channel directly
        } catch (error) {
          // Handle error silently
        }
      }
    })
  }
} catch (error) {
  // Handle error silently
}

// Export for module imports
export default notificationChannel

// Also expose globally for direct access from components
window.notificationChannel = notificationChannel
