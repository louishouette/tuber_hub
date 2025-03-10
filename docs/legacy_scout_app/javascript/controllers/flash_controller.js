import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = {
    autoHide: { type: Boolean, default: true },
    autoHideDelay: { type: Number, default: 5000 }
  }

  connect() {
    if (this.autoHideValue) {
      this.hideTimeout = setTimeout(() => {
        this.element.classList.add('opacity-0')
        setTimeout(() => {
          this.element.remove()
        }, 300) // matches the duration-300 class
      }, this.autoHideDelayValue)
    }
  }

  disconnect() {
    if (this.hideTimeout) {
      clearTimeout(this.hideTimeout)
    }
  }
}
