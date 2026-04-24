import { Controller } from "@hotwired/stimulus"

// Trims the day <select> to real calendar lengths for the chosen month/year (e.g. no 31 in November).
// Submit uses named user[birth_*] selects; this is a progressive enhancement when JS runs.
export default class extends Controller {
  static targets = ["year", "month", "day"]
  static values = {
    initial: String,
    promptDay: String
  }

  connect() {
    const init = (this.initialValue || "").trim()
    if (/^\d{4}-\d{2}-\d{2}$/.test(init)) {
      const [yStr, mStr, dStr] = init.split("-")
      this.yearTarget.value = yStr
      this.monthTarget.value = String(parseInt(mStr, 10))
      this.rebuildDayOptions()
      const d = parseInt(dStr, 10)
      if (d >= 1 && d <= this.maxDayFor(this.yearTarget.value, this.monthTarget.value)) {
        this.dayTarget.value = String(d)
      }
    } else {
      this.rebuildDayOptions()
    }
  }

  handleChange() {
    this.rebuildDayOptions()
  }

  maxDayFor(yearVal, monthVal) {
    const m = parseInt(monthVal, 10)
    if (!Number.isFinite(m) || m < 1 || m > 12) return 31
    const y = parseInt(yearVal, 10)
    const yy = Number.isFinite(y) ? y : 2001
    return new Date(yy, m, 0).getDate()
  }

  rebuildDayOptions() {
    const maxDay = this.maxDayFor(this.yearTarget.value, this.monthTarget.value)
    const previous = parseInt(this.dayTarget.value, 10)
    const daySelect = this.dayTarget
    const prompt = this.promptDayValue

    daySelect.innerHTML = ""
    const blank = document.createElement("option")
    blank.value = ""
    blank.textContent = prompt
    daySelect.appendChild(blank)

    for (let d = 1; d <= maxDay; d++) {
      const opt = document.createElement("option")
      opt.value = String(d)
      opt.textContent = String(d)
      daySelect.appendChild(opt)
    }

    if (Number.isFinite(previous) && previous >= 1 && previous <= maxDay) {
      daySelect.value = String(previous)
    }
  }
}
