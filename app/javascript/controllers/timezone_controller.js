import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input"]

  connect() {
    if (this.hasInputTarget && !this.inputTarget.value) {
      this.inputTarget.value = Intl.DateTimeFormat().resolvedOptions().timeZone
    }
  }
}
