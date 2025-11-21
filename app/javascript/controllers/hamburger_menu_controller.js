import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="hamburger-menu"
export default class extends Controller {
  static targets = ["menu", "toggle"]

  connect() {
    console.log("🍔 [STIMULUS] HamburgerMenuController connected")

    // ① 接続時に必ず閉じた状態にする
    if (this.hasMenuTarget) {
      this.menuTarget.classList.add('hidden')
    }

    // ESCキーでメニューを閉じる
    this.boundHandleEscape = this.handleEscape.bind(this)
    document.addEventListener('keydown', this.boundHandleEscape)

    // ② Turbo がスナップショット保存する前に必ず閉じる
    this.boundBeforeCache = () => {
      console.log("🍔 [STIMULUS] turbo:before-cache -> メニューを閉じる")
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

    console.log("🍔 [STIMULUS] HamburgerMenuController disconnected")
  }

  // メニューボタンがクリックされた時
  toggle(event) {
    event.preventDefault()
    event.stopPropagation()
    
    console.log("🍔 [STIMULUS] メニュー切り替え")
    
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
    
    console.log("🍔 [STIMULUS] メニューを閉じる")
    
    if (this.hasMenuTarget) {
      this.menuTarget.classList.add('hidden')
      this.disableOutsideClickDetection()
    }
  }

  // ESCキーでメニューを閉じる
  handleEscape(event) {
    if (event.key === 'Escape' && this.hasMenuTarget && !this.menuTarget.classList.contains('hidden')) {
      console.log("🍔 [STIMULUS] ESCキーでメニューを閉じる")
      this.close()
    }
  }

  // 外側クリック検知を有効にする
  enableOutsideClickDetection() {
    if (this.outsideClickListener) return // 既に有効な場合はスキップ
    
    this.outsideClickListener = (event) => {
      // 削除ボタンや削除モーダル関連の場合は無視
      if (this.isDeleteRelatedElement(event.target)) {
        console.log("🍔 [STIMULUS] 削除関連要素をクリック、メニュー処理をスキップ")
        return
      }
      
      // メニューやトグルボタンの外側をクリックした場合
      if (this.hasMenuTarget && 
          !this.menuTarget.contains(event.target) && 
          (!this.hasToggleTarget || !this.toggleTarget.contains(event.target))) {
        console.log("🍔 [STIMULUS] 外側クリック検知、メニューを閉じる")
        this.close()
      }
    }
    
    document.addEventListener('click', this.outsideClickListener)
    console.log("🍔 [STIMULUS] 外側クリック検知を有効化")
  }

  // 外側クリック検知を無効にする
  disableOutsideClickDetection() {
    if (this.outsideClickListener) {
      document.removeEventListener('click', this.outsideClickListener)
      this.outsideClickListener = null
      console.log("🍔 [STIMULUS] 外側クリック検知を無効化")
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
