import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="sidebar"
export default class extends Controller {
  static targets = ["menu", "accordion"]

  connect() {
    // Initialize accordions that should be open based on current path
    this.accordionTargets.forEach(accordion => {
      if (accordion.getAttribute('aria-expanded') === 'true') {
        const panel = document.getElementById(accordion.getAttribute('aria-controls'))
        if (panel) {
          panel.classList.remove('hidden')
          panel.classList.add('block')
        }
      }
    })
  }

  toggle() {
    this.menuTarget.classList.toggle('-translate-x-full')
  }

  toggleAccordion(event) {
    const button = event.currentTarget
    const panelId = button.getAttribute('aria-controls')
    const panel = document.getElementById(panelId)

    if (!panel) return

    const isExpanded = button.getAttribute('aria-expanded') === 'true'
    button.setAttribute('aria-expanded', !isExpanded)

    if (isExpanded) {
      panel.classList.remove('block')
      panel.classList.add('hidden')
    } else {
      panel.classList.remove('hidden')
      panel.classList.add('block')
    }
  }
}