import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["filter", "groups", "noResults", "dishId"]
  static values = { selectedDishName: String }

  connect() {
    this.boundCloseIfClickedOutside = this.closeIfClickedOutside.bind(this)
    document.addEventListener("click", this.boundCloseIfClickedOutside)

    if (this.hasGroupsTarget) this.groupsTarget.classList.add("hidden")
    if (this.hasNoResultsTarget) this.noResultsTarget.classList.add("hidden")
    this.markClosed()
  }

  disconnect() {
    document.removeEventListener("click", this.boundCloseIfClickedOutside)
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

  open() {
    if (!this.hasFilterTarget) return
    if (!this.hasSelectedDishNameValue) return

    if (this.hasGroupsTarget) this.groupsTarget.classList.remove("hidden")
    if (this.hasGroupsTarget && this.hasNoResultsTarget) this.filter()
    this.markOpen()

    const currentValue = this.normalize(this.filterTarget.value)
    const selectedValue = this.normalize(this.selectedDishNameValue)
    if (currentValue !== selectedValue) return

    this.filterTarget.value = ""
    if (this.hasGroupsTarget && this.hasNoResultsTarget) this.filter()
  }

  close() {
    if (!this.hasGroupsTarget) return
    this.groupsTarget.classList.add("hidden")
    if (this.hasNoResultsTarget) this.noResultsTarget.classList.add("hidden")
    this.markClosed()
  }

  closeIfClickedOutside(event) {
    if (!event?.target) return
    if (this.element.contains(event.target)) return

    this.close()
  }

  pick(event) {
    const dishId = event?.currentTarget?.dataset?.dishId
    if (!dishId) return

    if (!this.hasDishIdTarget) return
    this.dishIdTarget.value = dishId
    this.close()

    const form = this.dishIdTarget.form || this.element.closest("form")
    if (!form) return

    form.requestSubmit()
  }

  clear() {
    if (!this.hasDishIdTarget) return
    this.dishIdTarget.value = ""

    if (this.hasFilterTarget) this.filterTarget.value = ""
    if (this.hasGroupsTarget && this.hasNoResultsTarget) this.filter()
    this.close()

    const form = this.dishIdTarget.form || this.element.closest("form")
    if (!form) return

    form.requestSubmit()
  }

  markOpen() {
    if (!this.hasFilterTarget) return
    this.filterTarget.setAttribute("aria-expanded", "true")
  }

  markClosed() {
    if (!this.hasFilterTarget) return
    this.filterTarget.setAttribute("aria-expanded", "false")
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

