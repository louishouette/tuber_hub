import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["badge"]

  connect() {
    this.updateCount()
    this.bindEvents()
  }

  disconnect() {
    this.unbindEvents()
  }

  bindEvents() {
    this.receiveHandler = this.receive.bind(this)
    this.element.addEventListener('notification:received', this.receiveHandler)
  }

  unbindEvents() {
    this.element.removeEventListener('notification:received', this.receiveHandler)
  }

  receive(event) {
    if (event.detail && event.detail.count !== undefined) {
      this.updateBadge(event.detail.count)
    }
  }

  async updateCount() {
    try {
      const response = await fetch("/hub/notifications/count")
      if (!response.ok) throw new Error("Failed to load notification count")
      
      const data = await response.json()
      this.updateBadge(data.count)
    } catch (error) {
      console.error("Error fetching notification count:", error)
    }
  }

  updateBadge(count) {
    if (!this.hasBadgeTarget) return
    
    const badge = this.badgeTarget
    badge.textContent = count

    if (count > 0) {
      badge.classList.remove("hidden")
    } else {
      badge.classList.add("hidden")
    }
  }
}
