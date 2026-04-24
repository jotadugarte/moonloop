import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="unit-system-toggle"
export default class extends Controller {
  static targets = ["metric", "imperial"]

  connect() {
    this.toggle()
  }

  toggle() {
    const selectedSystem = this.element.querySelector('input[name="user[body_unit_system]"]:checked')?.value

    if (selectedSystem === 'imperial_us') {
      this.metricTargets.forEach(el => el.style.display = 'none')
      this.imperialTargets.forEach(el => el.style.display = '')
    } else {
      this.metricTargets.forEach(el => el.style.display = '')
      this.imperialTargets.forEach(el => el.style.display = 'none')
    }
  }
}
