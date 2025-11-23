import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="hamburger-menu"
export default class extends Controller {
  static targets = ["menu", "toggle"]

  connect() {
    // ① 接続時に必ず閉じた状態にする
    if (this.hasMenuTarget) {
      this.menuTarget.classList.add('hidden')
    }

    // ESCキーでメニューを閉じる
    this.boundHandleEscape = this.handleEscape.bind(this)
    document.addEventListener('keydown', this.boundHandleEscape)

    // ② Turbo がスナップショット保存する前に必ず閉じる
    this.boundBeforeCache = () => {
      this.close()
    }
    document.addEventListener("turbo:before-cache", this.boundBeforeCache)
  }

  disconnect() {
    // ESC キー
    if (this.boundHandleEscape) {
      document.removeEventListener('keydown', this.boundHandleEscape)
      this.boundHandleEscape = null
    }

    // turbo:before-cache
    if (this.boundBeforeCache) {
      document.removeEventListener("turbo:before-cache", this.boundBeforeCache)
      this.boundBeforeCache = null
    }

    // ③ 外側クリック検知もここで確実に解除しておく
    this.disableOutsideClickDetection()

  }

  // メニューボタンがクリックされた時
  toggle(event) {
    event.preventDefault()
    event.stopPropagation()
    
    if (this.hasMenuTarget) {
      this.menuTarget.classList.toggle('hidden')
      
      // メニューが開かれた時は外側クリック検知を有効化
      if (!this.menuTarget.classList.contains('hidden')) {
        this.enableOutsideClickDetection()
      } else {
        this.disableOutsideClickDetection()
      }
    }
  }

  // メニューを閉じる
  close(event) {
    if (event) {
      event.preventDefault()
      event.stopPropagation()
    }
    
    if (this.hasMenuTarget) {
      this.menuTarget.classList.add('hidden')
      this.disableOutsideClickDetection()
    }
  }

  // ESCキーでメニューを閉じる
  handleEscape(event) {
    if (event.key === 'Escape' && this.hasMenuTarget && !this.menuTarget.classList.contains('hidden')) {
      this.close()
    }
  }

  // 外側クリック検知を有効にする
  enableOutsideClickDetection() {
    if (this.outsideClickListener) return // 既に有効な場合はスキップ
    
    this.outsideClickListener = (event) => {
      // 削除ボタンや削除モーダル関連の場合は無視
      if (this.isDeleteRelatedElement(event.target)) {
        return
      }
      
      // メニューやトグルボタンの外側をクリックした場合
      if (this.hasMenuTarget && 
          !this.menuTarget.contains(event.target) && 
          (!this.hasToggleTarget || !this.toggleTarget.contains(event.target))) {
        this.close()
      }
    }
    
    document.addEventListener('click', this.outsideClickListener)
  }

  // 外側クリック検知を無効にする
  disableOutsideClickDetection() {
    if (this.outsideClickListener) {
      document.removeEventListener('click', this.outsideClickListener)
      this.outsideClickListener = null
    }
  }

  // 削除関連の要素かどうかチェック
  isDeleteRelatedElement(element) {
    return element.closest('[data-action*="delete-modal"]') ||
           element.closest('[data-delete-modal-target]') ||
           element.closest('[title*="削除"]') ||
           element.closest('[aria-label*="削除"]') ||
           element.closest('.delete-modal-trigger')
  }
}
