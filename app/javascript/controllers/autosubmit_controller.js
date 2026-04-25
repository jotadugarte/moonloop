import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  submit(event) {
    const target = event?.target
    const form = target?.form || this.element.closest("form")
    if (!form) return

    form.requestSubmit()
  }
}

