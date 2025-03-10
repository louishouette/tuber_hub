import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["select"]
  static values = { url: String }

  connect() {
    console.log("Filter controller connected")
  }

  updateTable() {
    const url = new URL(this.urlValue, window.location.origin)
    url.searchParams.set('season', this.selectTarget.value)
    
    const frame = document.querySelector("#price_records_table")
    frame.setAttribute("src", url.toString())
  }
}
