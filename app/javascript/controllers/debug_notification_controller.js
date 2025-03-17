import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["status"]

  connect() {
    console.log('Debug notification controller connected')
    this.createDebugButton()
  }

  createDebugButton() {
    // Only create debug UI in development environment
    if (process.env.NODE_ENV !== 'production') {
      // Create a floating debug button (more subtle design)
      const button = document.createElement('button')
      button.innerText = '🔔 Test'
      button.className = 'fixed bottom-5 right-5 z-50 bg-gray-200 hover:bg-gray-300 text-gray-700 font-medium py-1 px-3 text-xs rounded-full shadow-md opacity-70 hover:opacity-100 transition-opacity duration-200'
      button.dataset.action = 'click->debug-notification#triggerTestNotification'
      document.body.appendChild(button)
      
      // Create status display
      const statusElement = document.createElement('div')
      statusElement.className = 'fixed bottom-14 right-5 z-50 bg-white dark:bg-gray-800 text-gray-800 dark:text-gray-200 p-2 rounded shadow-lg text-xs max-w-xs hidden'
      statusElement.dataset.debugNotificationTarget = 'status'
      document.body.appendChild(statusElement)
    }
  }

  async triggerTestNotification() {
    console.log('Triggering test notification')
    this.showStatus('Sending test notification request...')
    
    try {
      const response = await fetch('/hub/debug/test_notification', {
        method: 'POST',
        headers: {
          'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').content,
          'Accept': 'application/json',
          'Content-Type': 'application/json'
        }
      })
      
      if (!response.ok) {
        throw new Error(`Server returned ${response.status}: ${response.statusText}`)
      }
      
      const data = await response.json()
      console.log('Test notification response:', data)
      this.showStatus(`Success! Notification ${data.id} created`)
      
      // Manually create a notification event for testing
      this.createTestNotificationEvent(data)
    } catch (error) {
      console.error('Error triggering test notification:', error)
      this.showStatus(`Error: ${error.message}`, true)
    }
  }
  
  createTestNotificationEvent(data) {
    console.log('Creating test notification events')
    
    // Manually dispatch toast event
    const toastEvent = new CustomEvent('notification:toast', {
      detail: data.notification,
      bubbles: true
    })
    
    // Manually dispatch counter event
    const countEvent = new CustomEvent('notification:received', {
      detail: { count: data.unread_count },
      bubbles: true
    })
    
    console.log('Dispatching events:', { toastEvent, countEvent })
    document.dispatchEvent(toastEvent)
    document.dispatchEvent(countEvent)
    
    this.showStatus('Manual events dispatched. Check console for details.')
  }
  
  showStatus(message, isError = false) {
    const statusEl = this.statusTarget
    statusEl.textContent = message
    statusEl.classList.remove('hidden')
    
    if (isError) {
      statusEl.classList.add('bg-red-100', 'text-red-800')
    } else {
      statusEl.classList.remove('bg-red-100', 'text-red-800')
    }
    
    // Hide after 5 seconds
    setTimeout(() => {
      statusEl.classList.add('hidden')
    }, 5000)
  }
}
