import { Controller } from "@hotwired/stimulus"
import { getAPIHeaders, showToast } from "../utils"

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
        headers: getAPIHeaders(),
        credentials: 'same-origin'
      })
      const data = await response.json()

      if (data.success) {
        this.updateButton(button, data.favorited, data.favorites_count)
        showToast(data.action === 'added' ? 'お気に入りに追加しました' : 'お気に入りから削除しました', 'success')
      } else {
        showToast(data.error || 'エラーが発生しました', 'error')
      }
    } catch (error) {
      // eslint-disable-next-line no-console
      console.error('Favorite toggle error:', error)
      showToast('ネットワークエラーが発生しました', 'error')
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

  // toast: use shared utils.showToast
}
