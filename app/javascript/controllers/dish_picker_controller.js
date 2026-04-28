import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["filter", "groups", "noResults"]
  static values = {
    selectId: String,
  }

  connect() {
    // no-op
  }

  disconnect() {
    // no-op
  }

  filter() {
    const query = this.normalize(this.filterTarget.value)
    const optionButtons = this.groupsTarget.querySelectorAll('[data-test="dish-picker-option"]')
    const groupNodes = this.groupsTarget.querySelectorAll('[data-test="dish-picker-group"]')

    let anyVisible = false
    optionButtons.forEach((button) => {
      const name = this.normalize(button.dataset.dishName || "")
      const matches = query.length === 0 || name.includes(query)
      button.closest("li")?.classList?.toggle("hidden", !matches)
      if (matches) anyVisible = true
    })

    groupNodes.forEach((group) => {
      const visibleOptions = group.querySelectorAll('li:not(.hidden)[data-test="dish-picker-option"], li:not(.hidden) [data-test="dish-picker-option"]')
      group.classList.toggle("hidden", visibleOptions.length === 0)
    })

    this.noResultsTarget.classList.toggle("hidden", anyVisible)
  }

  pick(event) {
    const dishId = event?.currentTarget?.dataset?.dishId
    if (!dishId) return

    const select = document.getElementById(this.selectIdValue)
    if (!select) return

    select.value = dishId

    const form = select.form || this.element.closest("form")
    if (!form) return

    form.requestSubmit()
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

