import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = {
    autoDismiss: { type: Boolean, default: true },
    dismissAfter: { type: Number, default: 5000 } // 5 seconds
  }

  static targets = ["container"]

  connect() {
    this.bindEvents()
    this.dismissTimeout = null
    console.log('Toast controller connected')
  }

  disconnect() {
    this.unbindEvents()
    if (this.dismissTimeout) {
      clearTimeout(this.dismissTimeout)
    }
  }

  bindEvents() {
    console.log('Binding toast events')
    this.notificationToastHandler = this.showNotificationToast.bind(this)
    document.addEventListener('notification:toast', this.notificationToastHandler)
    // Also add event listener directly to the container for backward compatibility
    this.element.addEventListener('notification:toast', this.notificationToastHandler)
  }

  unbindEvents() {
    console.log('Unbinding toast events')
    document.removeEventListener('notification:toast', this.notificationToastHandler)
    this.element.removeEventListener('notification:toast', this.notificationToastHandler)
  }

  // Create and show a toast from notification data
  showNotificationToast(event) {
    const notification = event.detail
    console.log('Received toast notification:', notification)

    if (!notification) return

    // Create toast element
    const toast = this.createToastElement(notification)
    
    // Add to container
    this.containerTarget.appendChild(toast)
    
    // Wait a moment then add the show class for animation
    setTimeout(() => {
      toast.classList.add('show')
    }, 10)

    // Auto dismiss after timeout if enabled
    if (this.autoDismissValue) {
      this.dismissTimeout = setTimeout(() => {
        this.dismissToast(toast)
      }, this.dismissAfterValue)
    }
  }

  // Create the toast element
  createToastElement(notification) {
    const toast = document.createElement('div')
    toast.className = 'fixed bottom-5 right-5 flex items-center w-full max-w-xs p-4 mb-4 text-gray-500 bg-white rounded-lg shadow dark:text-gray-400 dark:bg-gray-800 toast-notification opacity-0 transform translate-y-2 transition-all duration-300'
    toast.dataset.toastId = notification.id
    
    // Get icon and color based on notification type
    const iconClass = this.getIconClass(notification.notification_type || 'info')
    const colorClass = this.getColorClass(notification.notification_type || 'info')
    
    toast.innerHTML = `
      <div class="inline-flex items-center justify-center flex-shrink-0 w-8 h-8 ${colorClass} rounded-lg">
        <i class="${iconClass}"></i>
      </div>
      <div class="ml-3 text-sm font-normal">${notification.message}</div>
      <button type="button" class="ml-auto -mx-1.5 -my-1.5 bg-white text-gray-400 hover:text-gray-900 rounded-lg focus:ring-2 focus:ring-gray-300 p-1.5 hover:bg-gray-100 inline-flex h-8 w-8 dark:text-gray-500 dark:hover:text-white dark:bg-gray-800 dark:hover:bg-gray-700" data-action="click->toast#close">
        <span class="sr-only">Close</span>
        <svg class="w-5 h-5" fill="currentColor" viewBox="0 0 20 20" xmlns="http://www.w3.org/2000/svg"><path fill-rule="evenodd" d="M4.293 4.293a1 1 0 011.414 0L10 8.586l4.293-4.293a1 1 0 111.414 1.414L11.414 10l4.293 4.293a1 1 0 01-1.414 1.414L10 11.414l-4.293 4.293a1 1 0 01-1.414-1.414L8.586 10 4.293 5.707a1 1 0 010-1.414z" clip-rule="evenodd"></path></svg>
      </button>
    `
    
    return toast
  }
  
  // Close a toast when the close button is clicked
  close(event) {
    const toast = event.currentTarget.closest('.toast-notification')
    if (toast) {
      this.dismissToast(toast)
    }
  }
  
  // Dismiss a toast with animation
  dismissToast(toast) {
    toast.classList.remove('show')
    toast.classList.add('hiding')
    
    // Remove from DOM after animation completes
    setTimeout(() => {
      if (toast.parentNode) {
        toast.parentNode.removeChild(toast)
      }
    }, 300) // match the animation duration
  }
  
  // Get icon class based on notification type
  getIconClass(type) {
    switch (type) {
      case 'success':
        return 'fa-solid fa-check w-5 h-5 text-white'
      case 'error':
        return 'fa-solid fa-xmark w-5 h-5 text-white'
      case 'warning':
        return 'fa-solid fa-exclamation w-5 h-5 text-white'
      case 'info':
      default:
        return 'fa-solid fa-info w-5 h-5 text-white'
    }
  }
  
  // Get color class based on notification type
  getColorClass(type) {
    switch (type) {
      case 'success':
        return 'bg-green-500'
      case 'error':
        return 'bg-red-500'
      case 'warning':
        return 'bg-yellow-500'
      case 'info':
      default:
        return 'bg-blue-500'
    }
  }
}
