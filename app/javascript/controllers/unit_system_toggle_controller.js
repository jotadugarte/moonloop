import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="unit-system-toggle"
export default class extends Controller {
  static targets = ["metric", "imperial", "unitRadio"]

  connect() {
    this.toggle()
  }

  toggle() {
    const isImperial = this.selectedSystem() === "imperial_us"
    this.metricTargets.forEach((el) => el.classList.toggle("hidden", isImperial))
    this.imperialTargets.forEach((el) => el.classList.toggle("hidden", !isImperial))
  }

  selectedSystem() {
    const checked = this.unitRadioTargets.find((r) => r.checked)
    return checked?.value
  }
}
