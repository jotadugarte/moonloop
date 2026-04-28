import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["filter", "groups"]
  static values = {
    selectId: String,
  }

  connect() {
    this.onSubmitEnd = this.onSubmitEnd.bind(this)

    const form = this.element.closest("form")
    if (!form) return

    form.addEventListener("turbo:submit-end", this.onSubmitEnd)
  }

  disconnect() {
    const form = this.element.closest("form")
    if (!form) return

    form.removeEventListener("turbo:submit-end", this.onSubmitEnd)
  }

  filter() {
    const query = this.normalize(this.filterTarget.value)
    const optionButtons = this.groupsTarget.querySelectorAll('[data-test="dish-picker-option"]')
    const groupNodes = this.groupsTarget.querySelectorAll('[data-test="dish-picker-group"]')

    optionButtons.forEach((button) => {
      const name = this.normalize(button.dataset.dishName || "")
      const matches = query.length === 0 || name.includes(query)
      button.closest("li")?.classList?.toggle("hidden", !matches)
    })

    groupNodes.forEach((group) => {
      const visibleOptions = group.querySelectorAll('li:not(.hidden)[data-test="dish-picker-option"], li:not(.hidden) [data-test="dish-picker-option"]')
      group.classList.toggle("hidden", visibleOptions.length === 0)
    })
  }

  pick(event) {
    const dishId = event?.currentTarget?.dataset?.dishId
    if (!dishId) return

    const select = document.getElementById(this.selectIdValue)
    if (!select) return

    select.value = dishId
    select.dispatchEvent(new Event("change", { bubbles: true }))
  }

  onSubmitEnd(event) {
    if (!event?.detail?.success) return

    const slot = this.element.closest('[data-test="menu-entry-slot"]')
    if (!slot) return

    const allSlots = Array.from(document.querySelectorAll('[data-test="menu-entry-slot"]'))
    const slotIndex = allSlots.indexOf(slot)
    if (slotIndex < 0) return

    const nextSlot = allSlots[slotIndex + 1]
    if (!nextSlot) return

    const nextFilter = nextSlot.querySelector('[data-test="dish-picker-filter"]')
    nextFilter?.focus?.()
  }

  normalize(value) {
    return (value || "")
      .toString()
      .normalize("NFD")
      .replace(/[\u0300-\u036f]/g, "")
      .toLowerCase()
      .trim()
  }
}

