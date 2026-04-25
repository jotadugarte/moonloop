import { Controller } from "@hotwired/stimulus"

// Client-side preview for recipe image file input (new/edit before submit).
export default class extends Controller {
  static targets = ["file", "wrapper", "image"]

  connect() {
    this.objectUrl = null
  }

  showPreview() {
    this.revokeObjectUrl()
    const file = this.fileTarget.files?.[0]
    if (!file) {
      this.wrapperTarget.classList.add("hidden")
      this.imageTarget.removeAttribute("src")
      return
    }
    this.objectUrl = URL.createObjectURL(file)
    this.imageTarget.src = this.objectUrl
    this.wrapperTarget.classList.remove("hidden")
  }

  disconnect() {
    this.revokeObjectUrl()
  }

  revokeObjectUrl() {
    if (!this.objectUrl) return
    URL.revokeObjectURL(this.objectUrl)
    this.objectUrl = null
  }
}
