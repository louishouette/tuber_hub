// Notification utility functions for shared logic across controllers
// This module uses modern JavaScript features and follows best practices for browser APIs

// Base API URL for notifications
const NOTIFICATION_API_BASE = '/hub/notifications';

// API calls for notifications with enhanced error handling and async/await
export const NotificationAPI = {
  /**
   * Fetch notification count for the current user
   * @returns {Promise<Object>} The count data with unread_count, total_count, and read_rate
   */
  async getCount() {
    try {
      // Try to use notification channel first if available
      const channel = window.notificationChannel;
      if (channel && typeof channel.requestCount === 'function') {
        // Request count update via Action Cable
        channel.requestCount();
        // Return a placeholder - the real data will come through the channel
        return { count: null, unread_count: null, total_count: null, read_rate: null };
      }
      
      // Fall back to AJAX if channel not available
      const response = await fetch(`${NOTIFICATION_API_BASE}/count`, {
        headers: {
          'Accept': 'application/json',
          'X-Requested-With': 'XMLHttpRequest'
        },
        signal: AbortSignal.timeout(5000) // Modern timeout API with AbortSignal
      });
      
      if (!response.ok) throw new Error(`Server returned ${response.status}`);
      return await response.json();
    } catch (error) {
      console.error("Error fetching notification count:", error);
      return { count: 0, unread_count: 0, total_count: 0, read_rate: 0 };
    }
  },

  /**
   * Fetch notification items HTML
   * @returns {Promise<string>} HTML content for notifications list
   */
  async getItems() {
    try {
      const response = await fetch(`${NOTIFICATION_API_BASE}/items`, {
        headers: {
          'Accept': 'text/html',
          'X-Requested-With': 'XMLHttpRequest'
        },
        signal: AbortSignal.timeout(5000)
      });
      
      if (!response.ok) throw new Error(`Server returned ${response.status}`);
      return await response.text();
    } catch (error) {
      console.error("Error fetching notification items:", error);
      return null;
    }
  },

  /**
   * Fetch empty state HTML
   * @returns {Promise<string>} HTML content for empty state
   */
  async getEmptyState() {
    try {
      const response = await fetch(`${NOTIFICATION_API_BASE}/empty_state`, {
        headers: {
          'Accept': 'text/html',
          'X-Requested-With': 'XMLHttpRequest'
        }
      });
      
      if (!response.ok) throw new Error(`Server returned ${response.status}`);
      return await response.text();
    } catch (error) {
      console.error("Error fetching empty state:", error);
      // Cache the fallback HTML for better performance
      if (!this._cachedEmptyState) {
        this._cachedEmptyState = NotificationDOM.getEmptyStateHTML();
      }
      return this._cachedEmptyState;
    }
  },

  /**
   * Dismiss a notification
   * @param {string} id - Notification ID
   * @returns {Promise<boolean>} Success status
   */
  async dismiss(id) {
    try {
      // Always try both methods for better reliability:
      // 1. Use Action Cable for real-time UI updates
      // 2. Use HTTP request to ensure database persistence
      let actionCableSuccess = false;
      let httpSuccess = false;

      // First try Action Cable for immediate UI updates
      const channel = window.notificationChannel;
      if (channel && typeof channel.perform === 'function') {
        try {
          // Use Action Cable to dismiss the notification
          channel.perform('dismiss', { id });
          actionCableSuccess = true;
        } catch (cableError) {
          console.warn('Action Cable dismiss failed:', cableError);
          // Continue to HTTP method even if this fails
        }
      }
      
      // Then ALWAYS make an HTTP request to ensure database persistence
      // Using encodeURIComponent for better security when handling user input IDs
      const safeId = encodeURIComponent(id);
      const csrfToken = this.getCsrfToken();
      
      const response = await fetch(`${NOTIFICATION_API_BASE}/${safeId}/dismiss`, {
        method: 'PATCH',
        headers: {
          'X-CSRF-Token': csrfToken,
          'Accept': 'application/json',
          'Content-Type': 'application/json'
        }
      });
      
      // Add detailed response handling
      if (response.ok) {
        // Optionally parse the response if the server sends useful data
        if (response.headers.get('Content-Type')?.includes('application/json')) {
          const data = await response.json();
          httpSuccess = data.success === false ? false : true;
        } else {
          httpSuccess = true;
        }
      }
      
      // Return true if either method succeeded
      return actionCableSuccess || httpSuccess;
    } catch (error) {
      console.error("Error dismissing notification:", error);
      return false;
    }
  },

  /**
   * Mark all notifications as read
   * @returns {Promise<boolean>} Success status
   */
  async markAllAsRead() {
    try {
      const csrfToken = this.getCsrfToken();
      
      const response = await fetch(`${NOTIFICATION_API_BASE}/mark_all_as_read`, {
        method: 'POST',
        headers: {
          'X-CSRF-Token': csrfToken,
          'Accept': 'application/json',
          'Content-Type': 'application/json'
        }
      });
      
      // Handle successful response with proper parsing
      if (response.ok) {
        // Only parse JSON if the response has a JSON content type
        if (response.headers.get('Content-Type')?.includes('application/json')) {
          try {
            // Parse response data for use with toast notifications
            const data = await response.json();
            
            // IMPORTANT: Don't create a toast here - the server is already sending one
            // The bug is that we're getting multiple toasts because:
            // 1. The server sends a toast via the notification channel
            // 2. We're also trying to create one here
            // So we'll skip creating another toast and just handle the counter
            this.updateCounter(0); // Update the counter immediately 
            return true;
          } catch (parseError) {
            console.warn('Error parsing JSON response:', parseError);
            // Continue even if JSON parsing fails
            return response.ok;
          }
        } else {
          // Simple response with no JSON body
          return true;
        }
      }
      
      return false;
    } catch (error) {
      console.error("Error marking all notifications as read:", error);
      
      // Show error toast on failure
      const errorEvent = new CustomEvent('notification:toast', {
        detail: {
          type: 'error',
          message: 'Failed to mark notifications as read',
          timeout: 5000,
          id: `mark-all-read-error-${Date.now()}`
        }
      });
      
      window.dispatchEvent(errorEvent);
      return false;
    }
  },
  
  /**
   * Get CSRF token from meta tag
   * @returns {string} CSRF token
   * @private
   */
  getCsrfToken() {
    return document.querySelector("meta[name='csrf-token']")?.content || '';
  },
  
  /**
   * Update the notification counter in the UI
   * @param {number} count - New count value
   */
  updateCounter(count) {
    // Use the DOM utility to update the counter
    NotificationDOM.updateCounter(count);
  }
}

// DOM manipulation and event helpers with improved browser compatibility and performance
export const NotificationDOM = {
  // Cache selectors for better performance
  _selectors: {
    counter: '[data-notification-counter-target="badge"]',
    notifications: '.notification-item'
  },
  
  /**
   * Get notification counter badge element
   * @returns {HTMLElement|null} Badge element or null
   */
  getBadgeElement() {
    return document.querySelector(this._selectors.counter);
  },

  /**
   * Update notification counter with new count
   * @param {number} count - The new notification count
   */
  updateCounter(count) {
    // Ensure count is a number and not NaN
    const safeCount = Number.isInteger(count) ? count : 0;
    
    // Use event bus for component communication
    if (window.notificationEventBus) {
      window.notificationEventBus.emit('notification:count-updated', { count: safeCount });
    }
    
    // Also fire DOM CustomEvent for backward compatibility
    document.dispatchEvent(new CustomEvent('notification:received', { 
      detail: { count: safeCount },
      bubbles: true
    }));
    
    // Update any visible badges directly for immediate feedback
    const badge = this.getBadgeElement();
    if (badge) {
      badge.textContent = safeCount > 0 ? safeCount.toString() : '';
      badge.classList.toggle('hidden', safeCount === 0);
    }
  },

  /**
   * Decrement the current counter by 1
   * Used when dismissing a notification to provide immediate feedback
   */
  decrementCounter() {
    // Get current count, ensuring it's a number
    const currentCount = this.currentCount || 0;
    
    // Never go below zero
    const newCount = Math.max(0, currentCount - 1);
    
    // Update the counter with the new value
    this.updateCounter(newCount);
  },

  /**
   * Broadcast notification dismissed event
   * @param {string} id - ID of the dismissed notification
   */
  broadcastDismissEvent(id) {
    if (!id) return;
    
    const eventData = { id, timestamp: Date.now() };
    
    // Use event bus for consistent event handling - import directly, don't rely on window
    if (typeof notificationEventBus !== 'undefined') {
      notificationEventBus.emit('notification:dismissed', eventData);
    }
    
    // Also dispatch DOM event for backward compatibility
    document.dispatchEvent(new CustomEvent('notification:dismissed', {
      detail: eventData,
      bubbles: true
    }));
    
    // Update the counter immediately to match the current state
    // We decrement the current counter instead of making a new request
    this.decrementCounter();
    
    // Also remove any matching elements if they exist elsewhere on the page
    document.querySelectorAll(`[data-notification-id="${id}"]`).forEach(element => {
      if (element.closest('.notification-item')) {
        this.animate(element.closest('.notification-item'), {
          opacity: '0',
          transform: 'translateX(10px)'
        });
        setTimeout(() => element.closest('.notification-item').remove(), 300);
      }
    });
  },

  /**
   * Apply animation to an element with improved handling
   * @param {HTMLElement} element - Element to animate
   * @param {Object} options - Animation options
   */
  animate(element, { opacity, transform, transition = 'opacity 0.3s, transform 0.3s' }) {
    if (!element) return;
    
    // Apply the CSS transition animation
    element.style.transition = transition;
    
    // Apply styles after a micro-task to ensure transition works
    setTimeout(() => {
      if (opacity !== undefined) element.style.opacity = opacity;
      if (transform !== undefined) element.style.transform = transform;
    }, 0);
  },

  /**
   * Generate empty state HTML using Flowbite components
   * @returns {string} HTML for empty state
   */
  getEmptyStateHTML() {
    return `
      <div class="py-8 px-4 text-center text-gray-500 dark:text-gray-400">
        <div class="flex flex-col items-center">
          <svg class="w-14 h-14 mb-3 opacity-60 text-gray-400 dark:text-gray-500" fill="none" stroke="currentColor" viewBox="0 0 24 24" aria-hidden="true">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M18.364 18.364A9 9 0 005.636 5.636m12.728 12.728A9 9 0 015.636 5.636m12.728 12.728L5.636 5.636"></path>
          </svg>
          <p class="font-medium text-base mb-1">No notifications</p>
          <p class="text-xs text-gray-400 dark:text-gray-500">You're all caught up!</p>
        </div>
      </div>
    `;
  },
  
  /**
   * Creates a toast notification using Flowbite
   * @param {Object} options - Toast options
   * @param {string} options.message - Message to display
   * @param {string} options.type - Notification type (info, success, warning, error)
   * @param {number} options.duration - Duration in ms (default: 3000ms)
   */
  createToast({ message, type = 'info', duration = 3000 }) {
    // Only create if Flowbite is available
    if (!window._flowbite?.toast) {
      // Fallback to console for critical errors if no toast available
      if (type === 'error') {
        console.error(message);
      }
      return;
    }
    
    const options = {
      message,
      duration,
      position: 'top-right',
      style: type // Flowbite will apply the right style based on type
    };
    
    // Create and show the toast
    window._flowbite.toast(options);
  }
}
