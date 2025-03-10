import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = {
    timeout: Number
  }

  connect() {
    setTimeout(() => {
      this.element.remove()
    }, this.timeoutValue)
  }
}
