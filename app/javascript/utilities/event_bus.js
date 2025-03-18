/**
 * A simple event bus for centralized event management
 * This allows decoupling between components while maintaining communication
 */
class EventBus {
  constructor() {
    this.events = {}
  }

  /**
   * Subscribe to an event
   * @param {string} event - Event name
   * @param {Function} callback - Function to call when event is triggered
   * @returns {Function} Unsubscribe function
   */
  on(event, callback) {
    if (!this.events[event]) {
      this.events[event] = []
    }
    
    this.events[event].push(callback)
    
    // Return unsubscribe function
    return () => {
      this.events[event] = this.events[event].filter(cb => cb !== callback)
    }
  }

  /**
   * Emit an event with data
   * @param {string} event - Event name
   * @param {*} data - Event data
   */
  emit(event, data) {
    if (this.events[event]) {
      this.events[event].forEach(callback => {
        callback(data)
      })
    }
  }

  /**
   * Remove all listeners for an event
   * @param {string} event - Event name
   */
  off(event) {
    if (this.events[event]) {
      delete this.events[event]
    }
  }
}

// Create a singleton instance
const notificationEventBus = new EventBus()

export default notificationEventBus
