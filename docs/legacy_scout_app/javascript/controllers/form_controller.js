import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  submit(event) {
    // Submit the form when the select value changes
    event.target.form.requestSubmit()
  }
}
