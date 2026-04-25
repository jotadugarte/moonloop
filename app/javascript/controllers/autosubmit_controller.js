import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static lastPointerFocusKey = null

  connect() {
    this.lastFocusedName = null
    this.shouldRestoreFocus = false
    this.nextFocusKey = null
    this.onSubmitEnd = this.onSubmitEnd.bind(this)
    this.onPointerDownCapture = this.onPointerDownCapture.bind(this)
    this.element.addEventListener("turbo:submit-end", this.onSubmitEnd)
    document.addEventListener("pointerdown", this.onPointerDownCapture, true)
  }

  disconnect() {
    this.element.removeEventListener("turbo:submit-end", this.onSubmitEnd)
    document.removeEventListener("pointerdown", this.onPointerDownCapture, true)
  }

  onPointerDownCapture(event) {
    const el = event?.target?.closest?.("[data-focus-key]")
    this.constructor.lastPointerFocusKey = el?.dataset?.focusKey || null
  }

  submit(event) {
    const target = event?.target
    const targetName = target?.getAttribute?.("name") || null
    this.nextFocusKey =
      event?.relatedTarget?.dataset?.focusKey || this.constructor.lastPointerFocusKey || null

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
      window.requestAnimationFrame(() => {
        const next = document.querySelector(selector)
        next?.focus?.()
      })
      return
    }

    if (!this.lastFocusedName) return

    const next = this.element.querySelector(`[name="${CSS.escape(this.lastFocusedName)}"]`)
    next?.focus?.()
  }
}

