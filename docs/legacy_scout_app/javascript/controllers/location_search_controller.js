import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "results", "hiddenInput"]
  static values = { url: String }

  connect() { this.hideResults() }

  search() {
    const query = this.inputTarget.value
    query.length < 2 ? this.hideResults() : this.fetchResults(query)
  }

  async fetchResults(query) {
    try {
      const response = await fetch(`${this.urlValue}?q=${encodeURIComponent(query)}`)
      if (!response.ok) throw new Error()
      const locations = await response.json()
      locations.length ? this.showResults(locations) : this.hideResults()
    } catch { this.hideResults() }
  }

  showResults(results) {
    this.resultsTarget.innerHTML = `
      <div class="max-h-60 overflow-y-auto">
        ${results.map(loc => `
          <button type="button"
                  data-action="click->location-search#selectResult"
                  data-id="${loc.id}"
                  data-name="${loc.name}"
                  class="w-full text-left px-4 py-2 text-sm hover:bg-gray-100 cursor-pointer">
            ${loc.name}
          </button>
        `).join('')}
      </div>
    `
    this.resultsTarget.classList.remove('hidden')
  }

  hideResults() { this.resultsTarget.classList.add('hidden') }

  selectResult({ currentTarget: btn }) {
    this.hiddenInputTarget.value = btn.dataset.id
    this.inputTarget.value = btn.dataset.name
    this.hideResults()
  }

  clickOutside({ target }) {
    if (!this.element.contains(target)) this.hideResults()
  }
}