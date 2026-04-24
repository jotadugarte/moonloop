import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="timezone-autodetect"
export default class extends Controller {
  static targets = ["input"]

  connect() {
    if (this.inputTarget.value) return

    try {
      this.applyDetectedTimezone()
    } catch {
      // Intl / DOM may fail in restricted environments; omit autodetect
    }
  }

  applyDetectedTimezone() {
    const iana = Intl.DateTimeFormat().resolvedOptions().timeZone
    if (!iana) return

    const option = this.findOptionForIana(iana) || this.findOptionByGmtOffset()
    if (option) this.inputTarget.value = option.value
  }

  findOptionForIana(iana) {
    return Array.from(this.inputTarget.options).find((opt) => opt.value === iana)
  }

  findOptionByGmtOffset() {
    const date = new Date()
    const offset = -date.getTimezoneOffset()
    const sign = offset >= 0 ? "+" : "-"
    const pad = (num) => String(num).padStart(2, "0")
    const offsetString = `(GMT${sign}${pad(Math.abs(Math.floor(offset / 60)))}:${pad(Math.abs(offset % 60))})`
    return Array.from(this.inputTarget.options).find((opt) => opt.text.includes(offsetString))
  }
}
