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
    if (this.isoDatePattern.test(init)) {
      this.hydrateFromInitial(init)
    } else {
      this.rebuildDayOptions()
    }
  }

  get isoDatePattern() {
    return /^\d{4}-\d{2}-\d{2}$/
  }

  hydrateFromInitial(init) {
    const [yStr, mStr, dStr] = init.split("-")
    this.yearTarget.value = yStr
    this.monthTarget.value = String(parseInt(mStr, 10))
    this.rebuildDayOptions()
    this.selectDayIfInRange(dStr)
  }

  selectDayIfInRange(dStr) {
    const d = parseInt(dStr, 10)
    const max = this.maxDayFor(this.yearTarget.value, this.monthTarget.value)
    if (d >= 1 && d <= max) this.dayTarget.value = String(d)
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
    this.fillDaySelect(maxDay, previous)
  }

  fillDaySelect(maxDay, previous) {
    const daySelect = this.daySelectElement
    daySelect.innerHTML = ""
    daySelect.appendChild(this.blankDayOption())

    for (let d = 1; d <= maxDay; d++) {
      daySelect.appendChild(this.dayOption(d))
    }

    if (Number.isFinite(previous) && previous >= 1 && previous <= maxDay) {
      daySelect.value = String(previous)
    }
  }

  get daySelectElement() {
    return this.dayTarget
  }

  blankDayOption() {
    const blank = document.createElement("option")
    blank.value = ""
    blank.textContent = this.promptDayValue
    return blank
  }

  dayOption(d) {
    const opt = document.createElement("option")
    opt.value = String(d)
    opt.textContent = String(d)
    return opt
  }
}
