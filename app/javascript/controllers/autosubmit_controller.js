import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["form"]

  submit() {
    const form = this.formTarget || this.element.closest("form")
    if (!form) return

    form.requestSubmit()
  }
}

