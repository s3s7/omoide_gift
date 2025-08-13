import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="delete-modal"
export default class extends Controller {
  static targets = ["modal", "itemName", "confirmButton", "cancelButton"]
  static values = { deleteUrl: String, itemName: String, csrfToken: String }

  connect() {
    console.log("🗑️ [STIMULUS] DeleteModalController connected")
    console.log("🗑️ [STIMULUS] Modal target found:", this.hasModalTarget)
    if (this.hasModalTarget) {
      console.log("🗑️ [STIMULUS] Modal element:", this.modalTarget)
    }
  }

  // モーダルを表示
  show(event) {
    event.preventDefault()
    console.log("🗑️ [STIMULUS] 削除モーダル表示開始")
    
    // データを取得
    const button = event.currentTarget
    this.deleteUrlValue = button.dataset.deleteUrl
    this.itemNameValue = button.dataset.itemName
    this.csrfTokenValue = button.dataset.csrfToken

    console.log("🗑️ [STIMULUS] データ取得:", {
      item: this.itemNameValue,
      hasUrl: !!this.deleteUrlValue,
      hasToken: !!this.csrfTokenValue
    })

    // モーダルターゲットの確認
    if (!this.hasModalTarget) {
      console.error("🗑️ [STIMULUS] ERROR: Modal target not found!")
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
    
    console.log("🗑️ [STIMULUS] 削除モーダル表示完了")
  }

  // モーダルを非表示
  hide(event) {
    if (event) {
      event.preventDefault()
    }
    
    console.log("🗑️ [STIMULUS] モーダル非表示開始")
    
    this.modalTarget.classList.add('hidden')
    this.modalTarget.classList.remove('flex')
    document.body.style.overflow = 'auto'
    
    // ESCキーイベントを削除
    if (this.boundHandleEscape) {
      document.removeEventListener('keydown', this.boundHandleEscape)
    }
    
    console.log("🗑️ [STIMULUS] モーダル非表示完了")
  }

  // 削除を確認して実行
  confirm(event) {
    event.preventDefault()
    console.log("🗑️ [STIMULUS] 削除確認ボタンクリック")
    
    this.hide()
    this.submitDeleteForm()
  }

  // キャンセル
  cancel(event) {
    event.preventDefault()
    console.log("🗑️ [STIMULUS] キャンセルボタンクリック")
    this.hide()
  }

  // 背景クリックでモーダルを閉じる
  backdropClick(event) {
    if (event.target === this.modalTarget) {
      console.log("🗑️ [STIMULUS] 背景クリックでモーダルを閉じる")
      this.hide()
    }
  }

  // ESCキーでモーダルを閉じる
  handleEscape(event) {
    if (event.key === 'Escape') {
      console.log("🗑️ [STIMULUS] ESCキーでモーダルを閉じる")
      this.hide()
    }
  }

  // 削除フォームを送信
  submitDeleteForm() {
    console.log("🗑️ [STIMULUS] 削除フォーム送信:", {
      deleteUrl: this.deleteUrlValue,
      csrfToken: !!this.csrfTokenValue
    })

    if (!this.deleteUrlValue || !this.csrfTokenValue) {
      console.error("🗑️ [STIMULUS] 削除URLまたはCSRFトークンが不足しています")
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

    console.log("🗑️ [STIMULUS] 削除フォーム送信完了")
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
    console.log("🗑️ [STIMULUS] DeleteModalController disconnected")
  }
}