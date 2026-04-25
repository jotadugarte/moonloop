import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = {
    freeformId: String,
  }

  clearDone(event) {
    if (!event?.detail?.success) return

    const id = this.freeformIdValue
    if (!id) return

    const input = document.getElementById(id)
    if (!input) return

    input.value = ""
  }
}

