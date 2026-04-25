import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    this.lastFocusedName = null
    this.shouldRestoreFocus = false
    this.nextFocusKey = null
    this.onSubmitEnd = this.onSubmitEnd.bind(this)
    this.element.addEventListener("turbo:submit-end", this.onSubmitEnd)
  }

  disconnect() {
    this.element.removeEventListener("turbo:submit-end", this.onSubmitEnd)
  }

  submit(event) {
    const target = event?.target
    const targetName = target?.getAttribute?.("name") || null
    this.nextFocusKey = event?.relatedTarget?.dataset?.focusKey || null

    const isChange = event?.type === "change"
    this.shouldRestoreFocus = isChange || Boolean(this.nextFocusKey)
    this.lastFocusedName = isChange ? targetName : null

    const form = target?.form || this.element.closest("form")
    if (!form) return

    form.requestSubmit()
  }

  onSubmitEnd(event) {
    if (!event?.detail?.success) return
    if (!this.shouldRestoreFocus) return

    if (this.nextFocusKey) {
      const selector = `[data-focus-key="${CSS.escape(this.nextFocusKey)}"]`
      const next = document.querySelector(selector)
      next?.focus?.()
      return
    }

    if (!this.lastFocusedName) return

    const next = this.element.querySelector(`[name="${CSS.escape(this.lastFocusedName)}"]`)
    next?.focus?.()
  }
}

