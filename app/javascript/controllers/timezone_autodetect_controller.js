import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="timezone-autodetect"
export default class extends Controller {
  static targets = ["input"]

  connect() {
    // If the input already has a value (e.g. from a failed form submission or existing profile), don't overwrite it
    if (this.inputTarget.value) return

    try {
      const timezone = Intl.DateTimeFormat().resolvedOptions().timeZone
      if (timezone) {
        // Attempt to select the autodetected timezone if it exists in the select options
        // Rails time_zone_select uses Rails time zone names (e.g. "Eastern Time (US & Canada)") 
        // as the display text, but the *value* of the option is typically the tzinfo name 
        // like "America/New_York" (if configured with ActiveSupport::TimeZone::MAPPING).
        // Let's iterate options and match the value.
        const options = Array.from(this.inputTarget.options)
        let option = options.find(opt => opt.value === timezone)
        
        if (!option) {
          const date = new Date()
          const offset = -date.getTimezoneOffset()
          const sign = offset >= 0 ? '+' : '-'
          const pad = (num) => String(num).padStart(2, '0')
          const offsetString = `(GMT${sign}${pad(Math.abs(Math.floor(offset / 60)))}:${pad(Math.abs(offset % 60))})`
          option = options.find(opt => opt.text.includes(offsetString))
        }

        if (option) {
          this.inputTarget.value = option.value
        }
      }
    } catch (e) {
      console.warn("Could not autodetect timezone:", e)
    }
  }
}
