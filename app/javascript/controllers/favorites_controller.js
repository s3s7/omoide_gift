import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="favorites"
export default class extends Controller {
  static targets = ["button", "heart", "count"]
  static values = { recordId: Number }

  connect() {
    // No-op: click handled via action on button
  }

  async toggle(event) {
    if (event) {
      event.preventDefault()
      event.stopPropagation()
    }

    const giftRecordId = this.recordIdValue || this.element.dataset.giftRecordId
    if (!giftRecordId) return

    const button = this.buttonTarget || this.element.querySelector('.favorite-button')
    if (!button) return

    this.setLoading(button, true)

    try {
      const response = await fetch(`/gift_records/${giftRecordId}/toggle_favorite`, {
        method: 'POST',
        headers: this.apiHeaders(),
        credentials: 'same-origin'
      })
      const data = await response.json()

      if (data.success) {
        this.updateButton(button, data.favorited, data.favorites_count)
        this.showToast(data.action === 'added' ? 'お気に入りに追加しました' : 'お気に入りから削除しました', 'success')
      } else {
        this.showToast(data.error || 'エラーが発生しました', 'error')
      }
    } catch (error) {
      // eslint-disable-next-line no-console
      console.error('Favorite toggle error:', error)
      this.showToast('ネットワークエラーが発生しました', 'error')
    } finally {
      this.setLoading(button, false)
    }
  }

  updateButton(button, favorited, favoritesCount) {
    const heart = this.heartTarget || button.querySelector('.favorite-heart')
    const countEl = this.hasCountTarget ? this.countTarget : button.querySelector('.favorite-count')

    button.dataset.favorited = String(favorited)
    button.classList.toggle('favorited', favorited)

    if (heart) {
      heart.className = `favorite-heart ${favorited ? 'fas' : 'far'} fa-heart`
      if (favorited) {
        heart.style.animation = 'none'
        setTimeout(() => { heart.style.animation = 'heartBeat 0.3s ease' }, 10)
      }
    }

    if (favoritesCount > 0) {
      if (countEl) {
        countEl.textContent = favoritesCount
      } else {
        const newCount = document.createElement('span')
        newCount.className = 'favorite-count'
        newCount.textContent = favoritesCount
        button.appendChild(newCount)
      }
    } else if (countEl) {
      countEl.remove()
    }

    const title = favorited ? 'お気に入りから削除' : 'お気に入りに追加'
    button.title = title
    button.setAttribute('aria-label', title)
  }

  setLoading(button, isLoading) {
    button.classList.toggle('loading', isLoading)
    button.disabled = isLoading
  }

  apiHeaders() {
    const meta = document.querySelector('meta[name="csrf-token"]')
    const token = meta ? meta.getAttribute('content') : ''
    return {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
      'X-Requested-With': 'XMLHttpRequest',
      'X-CSRF-Token': token
    }
  }

  showToast(message, type = 'info') {
    const existing = document.querySelector('.favorite-toast')
    if (existing) existing.remove()

    const toast = document.createElement('div')
    toast.className = 'favorite-toast fixed top-4 right-4 z-50 px-4 py-2 rounded-lg shadow-lg max-w-xs transform transition-all duration-300 translate-x-full opacity-0'

    if (type === 'success') {
      toast.classList.add('bg-green-500', 'text-white')
      toast.innerHTML = `<i class="fas fa-check mr-2"></i>${message}`
    } else if (type === 'error') {
      toast.classList.add('bg-red-500', 'text-white')
      toast.innerHTML = `<i class="fas fa-exclamation-triangle mr-2"></i>${message}`
    } else {
      toast.classList.add('bg-blue-500', 'text-white')
      toast.innerHTML = `<i class="fas fa-info-circle mr-2"></i>${message}`
    }

    document.body.appendChild(toast)
    setTimeout(() => { toast.classList.remove('translate-x-full', 'opacity-0') }, 100)
    setTimeout(() => {
      toast.classList.add('translate-x-full', 'opacity-0')
      setTimeout(() => { toast.remove() }, 300)
    }, 3000)
  }
}
