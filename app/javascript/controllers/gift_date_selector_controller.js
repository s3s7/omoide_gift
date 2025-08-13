import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="gift-date-selector"
export default class extends Controller {
  static targets = ["input"]

  connect() {
    if (this.hasInputTarget) {
      this.inputTarget.classList.remove('is-invalid', 'is-valid')
      this.inputTarget.addEventListener('change', this.validate)
    }
  }

  disconnect() {
    if (this.hasInputTarget) {
      this.inputTarget.removeEventListener('change', this.validate)
    }
  }

  setDate(event) {
    const type = event.params.dateType
    if (!this.hasInputTarget || !type) return
    let targetDate = new Date()
    switch (type) {
      case 'today':
        targetDate = new Date()
        break
      case 'yesterday':
        targetDate = new Date()
        targetDate.setDate(targetDate.getDate() - 1)
        break
      case 'week_ago':
        targetDate = new Date()
        targetDate.setDate(targetDate.getDate() - 7)
        break
      default:
        return
    }
    const formatted = targetDate.toISOString().split('T')[0]
    this.inputTarget.value = formatted
    this.inputTarget.dispatchEvent(new Event('change', { bubbles: true }))
    this.inputTarget.focus()
    this.inputTarget.classList.add('is-valid')
    setTimeout(() => this.inputTarget.classList.remove('is-valid'), 1500)
  }

  validate = () => {
    if (!this.hasInputTarget) return
    const value = this.inputTarget.value
    const selectedDate = value ? new Date(value) : null
    const currentDate = new Date()
    const minDate = new Date()
    minDate.setFullYear(currentDate.getFullYear() - 100)
    const maxDate = new Date()
    maxDate.setFullYear(currentDate.getFullYear() + 1)

    this.inputTarget.classList.remove('is-valid', 'is-invalid')
    if (selectedDate && selectedDate >= minDate && selectedDate <= maxDate) {
      this.inputTarget.classList.add('is-valid')
    } else if (value) {
      this.inputTarget.classList.add('is-invalid')
    }
  }
}
