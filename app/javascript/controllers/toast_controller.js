import { Controller } from "@hotwired/stimulus"
import { NotificationDOM } from "utilities/notification_utils"
import notificationEventBus from "utilities/event_bus"
import { NotificationType, getNotificationAppearance } from "utilities/notification_types"

export default class extends Controller {
  static values = {
    autoDismiss: { type: Boolean, default: true },
    dismissAfter: { type: Number, default: 5000 } // 5 seconds
  }

  static targets = ["container"]

  connect() {
    this.bindEvents()
    this.dismissTimeout = null
  }

  disconnect() {
    this.unbindEvents()
    if (this.dismissTimeout) {
      clearTimeout(this.dismissTimeout)
    }
  }

  bindEvents() {
    // Handle toast notifications from direct DOM events (legacy support)
    this.domToastHandler = this.showNotificationToast.bind(this)
    document.addEventListener('notification:toast', this.domToastHandler)
    this.element.addEventListener('notification:toast', this.domToastHandler)
    
    // Handle notifications from Action Cable via event bus
    this.actionCableHandler = this.handleActionCableNotification.bind(this)
    notificationEventBus.on('notification:received', this.actionCableHandler)
  }

  unbindEvents() {
    // Clean up DOM event listeners
    document.removeEventListener('notification:toast', this.domToastHandler)
    this.element.removeEventListener('notification:toast', this.domToastHandler)
    
    // Clean up event bus listeners
    notificationEventBus.off('notification:received', this.actionCableHandler)
  }

  // Handle notifications coming from Action Cable
  handleActionCableNotification(data) {
    // Only show toast for notifications that should be shown as toasts
    if (data && data.notification && data.notification.show_toast) {
      this.showNotificationToast({ detail: data.notification })
    }
  }

  // Create and show a toast from notification data with improved feature detection
  showNotificationToast(event) {
    const notification = event.detail;
    
    if (!notification) {
      return;
    }

    // Check for container existence
    if (!this.hasContainerTarget) {
      console.warn('Toast controller: No container target found for toast notifications');
      return;
    }

    // Try to get the most common notification fields with improved fallbacks
    const message = notification.message || notification.body || notification.text || 'New notification';
    const type = notification.type || notification.notification_type || 'info';
    const id = notification.id || notification.notification_id;
    const notificationData = { ...notification, message, type, id };
    
    // Check for duplicates already visible (by ID if available)
    if (id) {
      const existingToast = this.containerTarget.querySelector(`[data-toast-id="${id}"]:not(.hiding)`);
      if (existingToast) {
        // Restart the timeout for existing toast
        if (this.autoDismissValue) {
          clearTimeout(this.dismissTimeout);
          this.dismissTimeout = setTimeout(() => {
            this.dismissToast(existingToast);
          }, this.dismissAfterValue);
        }
        return;
      }
    }
    
    // Create toast element
    const toast = this.createToastElement(notificationData);
    
    // Limit number of toasts to prevent UI clutter (keep max 5 toasts)
    const existingToasts = this.containerTarget.querySelectorAll('.toast-notification:not(.hiding)');
    if (existingToasts.length >= 5) {
      // Remove oldest toast (first one)
      this.dismissToast(existingToasts[0]);
    }
    
    // Add to container
    this.containerTarget.appendChild(toast);
    
    // Trigger layout recalculation for animation
    void toast.offsetWidth;
    
    // Add the show class for animation
    toast.classList.add('show');

    // Auto dismiss after timeout if enabled
    if (this.autoDismissValue) {
      this.dismissTimeout = setTimeout(() => {
        this.dismissToast(toast);
      }, this.dismissAfterValue);
    }
    
    // Log for debugging
    // Use a safer approach than relying on process.env which isn't available in some environments
    if (window.location.hostname === 'localhost' || window.location.hostname === '127.0.0.1') {
      console.debug('Toast displayed:', { type, message });
    }
  }

  // Create the toast element using Flowbite styling
  createToastElement(notification) {
    const toast = document.createElement('div');
    
    // Use responsive design with mobile-first approach
    toast.className = 'flex items-center w-full max-w-xs p-4 mb-4 text-gray-500 bg-white rounded-lg shadow dark:text-gray-400 dark:bg-gray-800 toast-notification opacity-0 transform translate-y-2 transition-all duration-300 sm:max-w-sm md:max-w-md';
    
    toast.dataset.toastId = notification.id || crypto.randomUUID?.() || Math.random().toString(36).substring(2, 9);
    toast.dataset.type = notification.type || NotificationType.INFO;
    toast.setAttribute('role', 'alert');
    
    // Get icon and color based on notification type
    const notificationType = notification.type || notification.notification_type || 'info';
    const iconClass = this.getIconClass(notificationType);
    const colorClass = this.getColorClass(notificationType);
    
    // Create timestamp if notification has a created_at field
    const timestamp = notification.created_at ? 
      '<span class="text-xs text-gray-400 dark:text-gray-500 block mt-1">' + this.formatTimestamp(notification.created_at) + '</span>' : '';
    
    toast.innerHTML = 
      '<div class="inline-flex items-center justify-center flex-shrink-0 w-8 h-8 ' + colorClass + ' rounded-lg">' + 
        '<i class="' + iconClass + '"></i>' + 
      '</div>' + 
      '<div class="ml-3 text-sm font-normal overflow-hidden">' + 
        '<div class="line-clamp-3">' + notification.message + '</div>' + 
        timestamp + 
      '</div>' + 
      '<button type="button" class="ml-auto -mx-1.5 -my-1.5 bg-white text-gray-400 hover:text-gray-900 rounded-lg focus:ring-2 focus:ring-gray-300 p-1.5 hover:bg-gray-100 inline-flex h-8 w-8 dark:text-gray-500 dark:hover:text-white dark:bg-gray-800 dark:hover:bg-gray-700" data-action="click->toast#close">' + 
        '<span class="sr-only">Close</span>' + 
        '<svg class="w-5 h-5" fill="currentColor" viewBox="0 0 20 20" xmlns="http://www.w3.org/2000/svg" aria-hidden="true"><path fill-rule="evenodd" d="M4.293 4.293a1 1 0 011.414 0L10 8.586l4.293-4.293a1 1 0 111.414 1.414L11.414 10l4.293 4.293a1 1 0 01-1.414 1.414L10 11.414l-4.293 4.293a1 1 0 01-1.414-1.414L8.586 10 4.293 5.707a1 1 0 010-1.414z" clip-rule="evenodd"></path></svg>' + 
      '</button>'
    
    return toast
  }
  
  // Close a toast when the close button is clicked
  close(event) {
    const toast = event.currentTarget.closest('.toast-notification')
    if (toast) {
      this.dismissToast(toast)
    }
  }
  
  // Dismiss a toast with animation and accessibility improvements
  dismissToast(toast) {
    if (!toast || toast.classList.contains('hiding')) return;
    
    toast.classList.remove('show');
    toast.classList.add('hiding');
    toast.setAttribute('aria-hidden', 'true');
    
    // Use NotificationDOM utility to animate the toast out
    NotificationDOM.animate(toast, {
      opacity: '0',
      transform: 'translateY(-10px)'
    });
    
    // Remove from DOM after animation completes
    setTimeout(() => {
      if (toast && toast.parentNode) {
        toast.parentNode.removeChild(toast);
      }
    }, 300); // match the animation duration
  }
  
  /**
   * Format a timestamp into a human-readable time
   * @param {string} timestamp - ISO timestamp or date string
   * @returns {string} Formatted time string
   */
  formatTimestamp(timestamp) {
    if (!timestamp) return '';
    
    try {
      const date = new Date(timestamp);
      
      // Check if the date is valid
      if (isNaN(date.getTime())) {
        return '';
      }
      
      // Get the time difference in minutes
      const now = new Date();
      const diffMs = now - date;
      const diffMins = Math.round(diffMs / 60000);
      
      // Format based on how recent it is
      if (diffMins < 1) {
        return 'Just now';
      } else if (diffMins < 60) {
        return diffMins + 'm ago';
      } else if (diffMins < 1440) { // Less than 24 hours
        const hours = Math.floor(diffMins / 60);
        return hours + 'h ago';
      } else {
        // Format as date for older notifications
        return date.toLocaleDateString(undefined, { month: 'short', day: 'numeric' });
      }
    } catch (e) {
      console.warn('Error formatting timestamp:', e);
      return '';
    }
  }
  
  // Get icon class based on notification type
  // Get icon class based on notification type using shared utility
  getIconClass(type) {
    const appearance = getNotificationAppearance(type)
    return `${appearance.icon} w-5 h-5 ${appearance.iconClass}`
  }
  
  // Get color class based on notification type using shared utility
  getColorClass(type) {
    const appearance = getNotificationAppearance(type)
    return appearance.bgClass
  }
}
