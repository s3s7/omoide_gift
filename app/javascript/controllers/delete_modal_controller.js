import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="delete-modal"
export default class extends Controller {
  static targets = ["modal", "itemName", "confirmButton", "cancelButton"]
  static values = { deleteUrl: String, itemName: String, csrfToken: String }

  connect() {
    if (this.hasModalTarget) {
      // no-op
    }
  }

  // モーダルを表示
  show(event) {
    event.preventDefault()
    
    // データを取得
    const button = event.currentTarget
    this.deleteUrlValue = button.dataset.deleteUrl
    this.itemNameValue = button.dataset.itemName
    this.csrfTokenValue = button.dataset.csrfToken

    // モーダルターゲットの確認
    if (!this.hasModalTarget) {
      return
    }

    // アイテム名を表示
    if (this.hasItemNameTarget) {
      this.itemNameTarget.textContent = this.itemNameValue
    }

    // モーダルを表示
    this.modalTarget.classList.remove('hidden')
    this.modalTarget.classList.add('flex')
    document.body.style.overflow = 'hidden'
    
    // ESCキー対応
    this.boundHandleEscape = this.handleEscape.bind(this)
    document.addEventListener('keydown', this.boundHandleEscape)
  }

  // モーダルを非表示
  hide(event) {
    if (event) {
      event.preventDefault()
    }
    
    this.modalTarget.classList.add('hidden')
    this.modalTarget.classList.remove('flex')
    document.body.style.overflow = 'auto'
    
    // ESCキーイベントを削除
    if (this.boundHandleEscape) {
      document.removeEventListener('keydown', this.boundHandleEscape)
    }
  }

  // 削除を確認して実行
  confirm(event) {
    event.preventDefault()
    
    this.hide()
    this.submitDeleteForm()
  }

  // キャンセル
  cancel(event) {
    event.preventDefault()
    this.hide()
  }

  // 背景クリックでモーダルを閉じる
  backdropClick(event) {
    if (event.target === this.modalTarget) {
      this.hide()
    }
  }

  // ESCキーでモーダルを閉じる
  handleEscape(event) {
    if (event.key === 'Escape') {
      this.hide()
    }
  }

  // 削除フォームを送信
  submitDeleteForm() {
    if (!this.deleteUrlValue || !this.csrfTokenValue) {
      return
    }

    const form = document.createElement('form')
    form.method = 'POST'
    form.action = this.deleteUrlValue

    // CSRF トークン
    const csrfInput = document.createElement('input')
    csrfInput.type = 'hidden'
    csrfInput.name = 'authenticity_token'
    csrfInput.value = this.csrfTokenValue
    form.appendChild(csrfInput)

    // DELETE メソッド
    const methodInput = document.createElement('input')
    methodInput.type = 'hidden'
    methodInput.name = '_method'
    methodInput.value = 'delete'
    form.appendChild(methodInput)

    // フォームをDOMに追加して送信
    document.body.appendChild(form)
    form.submit()
  }

  disconnect() {
    // コントローラーが切断された時のクリーンアップ
    if (this.boundHandleEscape) {
      document.removeEventListener('keydown', this.boundHandleEscape)
    }
    if (this.hasModalTarget) {
      this.modalTarget.classList.add('hidden')
      this.modalTarget.classList.remove('flex')
    }
    document.body.style.overflow = 'auto'
  }
}
