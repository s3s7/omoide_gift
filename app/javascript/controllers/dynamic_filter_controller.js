import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="dynamic-filter"
export default class extends Controller {
  static targets = [
    "filterTypeSelect",
    "filterTypeHidden",
    "relationshipSelect",
    "eventSelect",
    "placeholder"
  ]

  connect() {
    this.update()
  }

  update() {
    const selectedType = this.filterTypeSelectTarget?.value || ""

    // Update hidden field
    if (this.hasFilterTypeHiddenTarget) {
      this.filterTypeHiddenTarget.value = selectedType
    }

    // Hide all first
    this.hide(this.relationshipSelectTarget)
    this.hide(this.eventSelectTarget)
    this.hide(this.placeholderTarget)

    // Show by type and clear the other
    if (selectedType === "relationship") {
      this.show(this.relationshipSelectTarget)
      this.clearValue(this.eventSelectTarget)
    } else if (selectedType === "event") {
      this.show(this.eventSelectTarget)
      this.clearValue(this.relationshipSelectTarget)
    } else {
      this.show(this.placeholderTarget)
      this.clearValue(this.relationshipSelectTarget)
      this.clearValue(this.eventSelectTarget)
    }
  }

  show(element) {
    if (!element) return
    element.style.display = "block"
    element.classList.remove("hidden")
  }

  hide(element) {
    if (!element) return
    element.style.display = "none"
    element.classList.add("hidden")
  }

  clearValue(element) {
    if (!element) return
    if (element.tagName === "SELECT") {
      element.value = ""
    }
  }
}
