import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "results", "selectedId"]
  static values = {
    sectors: Array
  }

  connect() {
    console.log('Connected harvesting sector search')
    console.log('Sectors:', this.sectorsValue)
    this.hideResults()
  }

  search() {
    console.log('Searching...')
    const query = this.inputTarget.value.toLowerCase()
    console.log('Query:', query)
    if (query.length < 2) {
      this.hideResults()
      return
    }

    const results = this.sectorsValue.filter(sector => {
      const name = sector.name
      const lowercaseQuery = query.toLowerCase()
      const lowercaseName = name.toLowerCase()

      // Direct matches
      if (lowercaseName.includes(lowercaseQuery)) return true

      // Split into parts: [FBH, QG, LETTER/NUMBER, COLOR]
      const parts = name.split('-')
      const [prefix, zone, section, color] = parts

      // Match specific patterns:
      // 1. Section letter/number (A1, B2, C, etc.)
      if (section && section.toLowerCase().startsWith(lowercaseQuery)) return true
      
      // 2. Color (BLANC, OR, SANG)
      if (color && color.toLowerCase().startsWith(lowercaseQuery)) return true

      // 3. Handle combined section+color searches (e.g., 'a1b' for A1-BLANC)
      if (section && color && `${section}${color}`.toLowerCase().includes(lowercaseQuery)) return true

      // 4. Handle zone+section searches (e.g., 'qga' for QG-A1)
      if (zone && section && `${zone}${section}`.toLowerCase().includes(lowercaseQuery)) return true

      return false
    })

    console.log('Found results:', results)
    this.showResults(results)
  }

  showResults(results) {
    if (results.length === 0) {
      console.log('No results found')
      this.hideResults()
      return
    }

    const html = results
      .slice(0, 5)
      .map(sector => this.resultTemplate(sector))
      .join('')
    
    console.log('Setting HTML:', html)
    this.resultsTarget.innerHTML = html
    this.resultsTarget.classList.remove('hidden')
  }

  hideResults() {
    console.log('Hiding results')
    this.resultsTarget.classList.add('hidden')
  }

  selectResult(event) {
    const { id, name } = event.currentTarget.dataset
    this.inputTarget.value = name
    this.selectedIdTarget.value = id
    this.hideResults()
  }

  resultTemplate(sector) {
    const html = `
      <button type="button"
              data-action="click->harvesting-sector-search#selectResult"
              data-id="${sector.id}"
              data-name="${sector.name}"
              class="w-full text-left px-4 py-2 text-sm hover:bg-gray-100 cursor-pointer">
        ${sector.name}
      </button>
    `
    console.log('Generated template:', html)
    return html
  }

  clickOutside(event) {
    if (!this.element.contains(event.target)) {
      this.hideResults()
    }
  }
}
