import { Controller } from "@hotwired/stimulus"

// Client-side preview for recipe image file input (new/edit before submit).
export default class extends Controller {
  static targets = ["file", "wrapper", "image", "currentWrapper"]

  connect() {
    this.objectUrl = null
  }

  showPreview() {
    this.revokeObjectUrl()
    const file = this.fileTarget.files?.[0]
    if (!file) return this.clearPreview()

    this.applyFilePreview(file)
  }

  disconnect() {
    this.revokeObjectUrl()
  }

  prepareRemove(event) {
    this.fileTarget.value = ""
    this.clearPreview()
    if (!event?.defaultPrevented) return
  }

  clearPreview() {
    this.wrapperTarget.classList.add("hidden")
    this.imageTarget.removeAttribute("src")
    if (this.hasCurrentWrapperTarget) this.currentWrapperTarget.classList.remove("hidden")
  }

  applyFilePreview(file) {
    this.objectUrl = URL.createObjectURL(file)
    this.imageTarget.src = this.objectUrl
    this.wrapperTarget.classList.remove("hidden")
    if (this.hasCurrentWrapperTarget) this.currentWrapperTarget.classList.add("hidden")
  }

  revokeObjectUrl() {
    if (!this.objectUrl) return
    URL.revokeObjectURL(this.objectUrl)
    this.objectUrl = null
  }
}
