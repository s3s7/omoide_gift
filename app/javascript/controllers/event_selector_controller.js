import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="event-selector"
export default class extends Controller {
  static targets = ["select", "help"]

  connect() {
    if (this.hasSelectTarget) {
      this.handleChange = this.handleChange.bind(this)
      this.handleFocus = this.handleFocus.bind(this)
      this.handleBlur = this.handleBlur.bind(this)

      this.selectTarget.addEventListener('change', this.handleChange)
      this.selectTarget.addEventListener('focus', this.handleFocus)
      this.selectTarget.addEventListener('blur', this.handleBlur)

      // 初期状態は中立
      this.selectTarget.classList.remove('is-invalid', 'is-valid')
    }

    // キーボードショートカット: Ctrl+E でセレクトにフォーカス
    this.handleKeydown = (e) => {
      if (e.ctrlKey && e.key === 'e') {
        e.preventDefault()
        if (this.hasSelectTarget) this.selectTarget.focus()
      }
    }
    document.addEventListener('keydown', this.handleKeydown)
  }

  disconnect() {
    if (this.hasSelectTarget) {
      this.selectTarget.removeEventListener('change', this.handleChange)
      this.selectTarget.removeEventListener('focus', this.handleFocus)
      this.selectTarget.removeEventListener('blur', this.handleBlur)
    }
    document.removeEventListener('keydown', this.handleKeydown)
  }

  handleChange() {
    const select = this.selectTarget
    select.classList.remove('is-valid', 'is-invalid')
    if (select.value && select.value !== '') {
      select.classList.add('is-valid')
    }
  }

  handleFocus() {
    if (!this.hasHelpTarget) return
    this.helpTarget.style.fontWeight = 'bold'
    this.helpTarget.style.color = '#0d6efd'
  }

  handleBlur() {
    if (!this.hasHelpTarget) return
    this.helpTarget.style.fontWeight = 'normal'
    this.helpTarget.style.color = '#6c757d'
  }
}
