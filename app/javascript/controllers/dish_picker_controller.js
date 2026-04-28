import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["filter", "groups", "noResults", "dishId"]

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

    if (!this.hasDishIdTarget) return
    this.dishIdTarget.value = dishId

    const form = this.dishIdTarget.form || this.element.closest("form")
    if (!form) return

    form.requestSubmit()
  }

  clear() {
    if (!this.hasDishIdTarget) return
    this.dishIdTarget.value = ""

    if (this.hasFilterTarget) this.filterTarget.value = ""
    if (this.hasGroupsTarget && this.hasNoResultsTarget) this.filter()

    const form = this.dishIdTarget.form || this.element.closest("form")
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

