import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="gift-date-selector"
export default class extends Controller {
  static targets = ["input"]

  connect() {
    // DOMが完全に読み込まれるまで少し待つ（Turbo対応）
    this.initializeAfterTurbo()
  }

  // Turbo対応の初期化
  initializeAfterTurbo() {
    // nextTickで実行してDOMが安定してから処理
    setTimeout(() => {
      this.initializeController()
    }, 0)
  }

  initializeController() {
    const inputElement = this.getInputElement()
    
    if (inputElement) {
      inputElement.classList.remove('is-invalid', 'is-valid')
      // 既存のイベントリスナーを削除してから追加（重複防止）
      inputElement.removeEventListener('change', this.validate)
      inputElement.addEventListener('change', this.validate)
    } else {
      // 少し待ってから再試行（DOM更新待ち）
      setTimeout(() => {
        const retryInputElement = this.getInputElement()
        if (retryInputElement) {
          this.initializeController()
        }
      }, 100)
    }
  }

  // Input要素を取得（targetまたは手動検索）
  getInputElement() {
    // Stimulusターゲットのみを使用
    if (this.hasInputTarget) {
      return this.inputTarget
    }
    return null
  }

  disconnect() {
    const inputElement = this.getInputElement()
    if (inputElement) {
      inputElement.removeEventListener('change', this.validate)
    }
  }

  setDate(event) {
    event.preventDefault()
    event.stopPropagation()
    
    // Input要素を取得
    const inputElement = this.getInputElement()
    
    if (!inputElement) return
    
    // 複数の方法でパラメータを取得を試行
    const type = this.getDateType(event)
    
    if (!type) return

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

    // 日付をYYYY-MM-DD形式でフォーマット
    const formatted = this.formatDateToString(targetDate)
    
    // 入力フィールドに値を設定
    inputElement.value = formatted
    
    // 複数のイベントを発火して確実に反映
    this.dispatchEvents(inputElement)
    
    // フォーカスして選択状態を示す
    inputElement.focus()
    
    // 成功を視覚的に示す
    this.showSuccess(inputElement)
  }

  // パラメータ取得のフォールバック処理
  getDateType(event) {
    // Stimulusパラメータのみを使用
    if (event?.params?.type) {
      return event.params.type
    }
    return null
  }

  // イベント発火処理
  dispatchEvents(inputElement) {
    const element = inputElement || this.getInputElement()
    if (!element) return
    
    const events = ['change', 'input', 'blur']
    events.forEach(eventType => {
      element.dispatchEvent(new Event(eventType, { 
        bubbles: true, 
        cancelable: true 
      }))
    })
  }

  // 日付を文字列にフォーマット（タイムゾーンを考慮）
  formatDateToString(date) {
    const year = date.getFullYear()
    const month = String(date.getMonth() + 1).padStart(2, '0')
    const day = String(date.getDate()).padStart(2, '0')
    return `${year}-${month}-${day}`
  }

  // 成功状態の表示
  showSuccess(inputElement) {
    const element = inputElement || this.getInputElement()
    if (!element) return
    
    element.classList.remove('is-invalid')
    element.classList.add('is-valid')
    
    // 一定時間後にクラスを削除
    setTimeout(() => {
      element.classList.remove('is-valid')
    }, 1500)
  }

  validate = () => {
    const inputElement = this.getInputElement()
    if (!inputElement) return
    
    const value = inputElement.value
    const selectedDate = value ? new Date(value) : null
    const currentDate = new Date()
    const minDate = new Date()
    minDate.setFullYear(currentDate.getFullYear() - 100)
    const maxDate = new Date()
    maxDate.setFullYear(currentDate.getFullYear() + 1)

    inputElement.classList.remove('is-valid', 'is-invalid')
    if (selectedDate && selectedDate >= minDate && selectedDate <= maxDate) {
      inputElement.classList.add('is-valid')
    } else if (value) {
      inputElement.classList.add('is-invalid')
    }
  }

}
