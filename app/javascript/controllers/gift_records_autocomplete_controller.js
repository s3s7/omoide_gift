import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="gift-records-autocomplete"
export default class extends Controller {
  static targets = ["input", "dropdown", "loading"]
  static values = {
    endpoint: { type: String, default: "/gift_records/autocomplete" },
    minLength: { type: Number, default: 1 },
    debounce: { type: Number, default: 300 },
    maxResults: { type: Number, default: 10 }
  }

  connect() {
    this.searchTimeoutId = null
    this.currentAbortController = null
    this.boundOutsideClick = this.handleOutsideClick.bind(this)
    document.addEventListener("click", this.boundOutsideClick)

    if (this.hasInputTarget) {
      this.inputTarget.addEventListener("input", this.handleInput)
      this.inputTarget.addEventListener("keydown", this.handleKeydown)
      this.inputTarget.dataset.autocompleteInitialized = "true"
    }
  }

  disconnect() {
    if (this.hasInputTarget) {
      this.inputTarget.removeEventListener("input", this.handleInput)
      this.inputTarget.removeEventListener("keydown", this.handleKeydown)
      this.inputTarget.dataset.autocompleteInitialized = "false"
    }

    document.removeEventListener("click", this.boundOutsideClick)

    if (this.currentAbortController) {
      this.currentAbortController.abort()
      this.currentAbortController = null
    }
    if (this.searchTimeoutId) {
      clearTimeout(this.searchTimeoutId)
      this.searchTimeoutId = null
    }
  }

  // Arrow functions to preserve 'this'
  handleInput = (event) => {
    const query = (event.target.value || "").trim()
    if (this.searchTimeoutId) clearTimeout(this.searchTimeoutId)

    if (query.length >= this.minLengthValue) {
      this.searchTimeoutId = setTimeout(() => this.performSearch(query), this.debounceValue)
    } else {
      this.hideDropdown()
    }
  }

  handleKeydown = (event) => {
    if (!this.hasDropdownTarget) return
    const items = this.dropdownTarget.querySelectorAll('.autocomplete-item')
    const activeItem = this.dropdownTarget.querySelector('.autocomplete-item.bg-primary-100')

    switch (event.key) {
      case 'ArrowDown':
        event.preventDefault()
        if (activeItem) {
          activeItem.classList.remove('bg-primary-100')
          const next = activeItem.nextElementSibling || items[0]
          next?.classList.add('bg-primary-100')
        } else if (items.length > 0) {
          items[0].classList.add('bg-primary-100')
        }
        break
      case 'ArrowUp':
        event.preventDefault()
        if (activeItem) {
          activeItem.classList.remove('bg-primary-100')
          const prev = activeItem.previousElementSibling || items[items.length - 1]
          prev?.classList.add('bg-primary-100')
        } else if (items.length > 0) {
          items[items.length - 1].classList.add('bg-primary-100')
        }
        break
      case 'Enter':
        if (activeItem) {
          event.preventDefault()
          activeItem.click()
        }
        break
      case 'Escape':
        this.hideDropdown()
        break
    }
  }

  handleOutsideClick(event) {
    if (!this.hasInputTarget || !this.hasDropdownTarget) return
    if (!this.inputTarget.contains(event.target) && !this.dropdownTarget.contains(event.target)) {
      this.hideDropdown()
    }
  }

  async performSearch(query) {
    if (!this.hasInputTarget || !this.hasDropdownTarget) return

    if (this.currentAbortController) {
      this.currentAbortController.abort()
    }
    this.currentAbortController = new AbortController()

    this.showLoading()
    const url = `${this.endpointValue}?q=${encodeURIComponent(query)}`

    try {
      const response = await fetch(url, {
        signal: this.currentAbortController.signal,
        headers: this.defaultHeaders()
      })
      if (!response.ok) throw new Error(`HTTP ${response.status}`)

      const data = await response.json()
      this.hideLoading()
      this.displayResults(Array.isArray(data.results) ? data.results.slice(0, this.maxResultsValue) : [])
    } catch (error) {
      if (error.name !== 'AbortError') {
        // eslint-disable-next-line no-console
        console.error('[Autocomplete] error', error)
        this.hideLoading()
        this.hideDropdown()
      }
    }
  }

  defaultHeaders() {
    return {
      'Accept': 'application/json',
      'X-Requested-With': 'XMLHttpRequest',
      'X-CSRF-Token': this.csrfToken()
    }
  }

  csrfToken() {
    const meta = document.querySelector('meta[name="csrf-token"]')
    return meta ? meta.getAttribute('content') : ''
  }

  displayResults(results) {
    if (!this.hasDropdownTarget) return
    if (!results || results.length === 0) {
      this.hideDropdown()
      return
    }

    const html = results.map((result) => this.buildItemHTML(result)).join('')
    this.dropdownTarget.innerHTML = html
    this.showDropdown()
    this.attachItemClickHandlers()
  }

  attachItemClickHandlers() {
    if (!this.hasDropdownTarget || !this.hasInputTarget) return
    const form = this.inputTarget.closest('form')
    this.dropdownTarget.querySelectorAll('.autocomplete-item').forEach((item) => {
      item.addEventListener('click', () => {
        const displayText = item.dataset.displayText || ''
        this.inputTarget.value = displayText
        this.hideDropdown()
        if (form) form.submit()
      })
    })
  }

  buildItemHTML(result) {
    const displayText = this.escapeHtml(result.display_text || result.name || '')
    const highlight = result.search_highlight || displayText
    const typeIcon = this.iconFor(result.type)
    const typeLabel = this.labelFor(result.type)

    return `
      <div class="autocomplete-item px-3 py-2 hover:bg-primary-50 cursor-pointer border-b border-gray-100 last:border-b-0"
           data-display-text="${displayText}" data-id="${result.id}">
        <div class="flex items-start space-x-2">
          <div class="flex-shrink-0 w-6 h-6 bg-primary-100 rounded-full flex items-center justify-center">
            <i class="${typeIcon} text-primary text-xs"></i>
          </div>
          <div class="flex-1 min-w-0">
            <div class="text-xs font-medium text-gray-900">${highlight}</div>
            <div class="text-xs text-gray-500 mt-0.5">${typeLabel}</div>
          </div>
        </div>
      </div>
    `
  }

  iconFor(type) {
    switch (type) {
      case 'item': return 'fas fa-gift'
      case 'memo': return 'fas fa-sticky-note'
      case 'name': return 'fas fa-user'
      case 'likes': return 'fas fa-thumbs-up'
      case 'user': return 'fas fa-user'
      case 'event': return 'fas fa-calendar'
      default: return 'fas fa-search'
    }
  }

  labelFor(type) {
    switch (type) {
      case 'item': return 'アイテム'
      case 'memo': return 'メモ'
      case 'name': return '名前'
      case 'likes': return '好きなもの'
      case 'user': return 'ユーザー'
      case 'event': return 'イベント'
      default: return '検索'
    }
  }

  showLoading() {
    if (this.hasLoadingTarget) {
      this.loadingTarget.classList.remove('hidden')
    }
  }

  hideLoading() {
    if (this.hasLoadingTarget) {
      this.loadingTarget.classList.add('hidden')
    }
  }

  showDropdown() {
    if (this.hasDropdownTarget) {
      this.dropdownTarget.classList.remove('hidden')
    }
  }

  hideDropdown() {
    if (this.hasDropdownTarget) {
      this.dropdownTarget.classList.add('hidden')
    }
  }

  escapeHtml(text) {
    const div = document.createElement('div')
    div.textContent = text
    return div.innerHTML
  }
}
