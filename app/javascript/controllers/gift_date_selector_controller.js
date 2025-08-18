import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="gift-date-selector"
export default class extends Controller {
  static targets = ["input"]
  static values = { debug: { type: Boolean, default: false } }

  connect() {
    this.debug('GiftDateSelector controller connected')
    this.debug('Element:', this.element)
    this.debug('Element HTML:', this.element.outerHTML)
    
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
      this.debug('Event listener added to input element')
      this.debug('Input element ID:', inputElement.id)
      this.debug('Input element value:', inputElement.value)
    } else {
      this.debug('No input element found for gift-date-selector controller')
      this.debug('Available children:', Array.from(this.element.children).map(el => el.tagName + (el.id ? '#' + el.id : '')))
      
      // 少し待ってから再試行（DOM更新待ち）
      setTimeout(() => {
        const retryInputElement = this.getInputElement()
        if (retryInputElement) {
          this.debug('Input element found on retry')
          this.initializeController()
        } else {
          console.warn('GiftDateSelector: input element still not found after retry')
          this.debug('Final element structure:', this.element.innerHTML)
        }
      }, 100)
    }
  }

  // Input要素を取得（targetまたは手動検索）
  getInputElement() {
    // 方法1: Stimulusターゲット（推奨）
    try {
      if (this.hasInputTarget) {
        this.debug('Found input via Stimulus target')
        return this.inputTarget
      }
    } catch (e) {
      this.debug('Stimulus target error:', e.message)
    }
    
    // 方法2: data-gift-date-selector-target="input"で検索
    const targetElement = this.element.querySelector('[data-gift-date-selector-target="input"]')
    if (targetElement) {
      this.debug('Found input via data-target attribute')
      return targetElement
    }
    
    // 方法3: date inputフィールドを検索
    const dateInput = this.element.querySelector('input[type="date"]')
    if (dateInput) {
      this.debug('Found input via date type selector')
      return dateInput
    }
    
    // 方法4: gift_at名前のinputを検索
    const nameInput = this.element.querySelector('input[name*="gift_at"]')
    if (nameInput) {
      this.debug('Found input via name attribute')
      return nameInput
    }
    
    this.debug('No input element found via any method')
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
    
    this.debug('setDate called')
    this.debug('Event:', event)
    this.debug('Current target:', event.currentTarget)
    
    // Input要素を取得
    const inputElement = this.getInputElement()
    
    if (!inputElement) {
      console.warn('GiftDateSelector: No input element found for setDate')
      this.debug('Controller element:', this.element)
      return
    }
    
    // 複数の方法でパラメータを取得を試行
    const type = this.getDateType(event)
    
    this.debug('Date type:', type)
    this.debug('Event params:', event.params)
    this.debug('Dataset:', event.currentTarget?.dataset)
    
    if (!type) {
      console.warn('GiftDateSelector: No date type parameter found')
      this.debug('Available dataset keys:', Object.keys(event.currentTarget?.dataset || {}))
      return
    }

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
        console.warn('GiftDateSelector: Unknown date type:', type)
        return
    }

    // 日付をYYYY-MM-DD形式でフォーマット
    const formatted = this.formatDateToString(targetDate)
    
    this.debug('Setting date to:', formatted)
    
    // 入力フィールドに値を設定
    inputElement.value = formatted
    
    // 複数のイベントを発火して確実に反映
    this.dispatchEvents(inputElement)
    
    // フォーカスして選択状態を示す
    inputElement.focus()
    
    // 成功を視覚的に示す
    this.showSuccess(inputElement)
    
    this.debug('Date successfully set to:', formatted)
  }

  // パラメータ取得のフォールバック処理
  getDateType(event) {
    // 方法1: Stimulusパラメータ（推奨）
    if (event.params && event.params.type) {
      this.debug('Got type from event.params:', event.params.type)
      return event.params.type
    }
    
    // 方法2: dataset（フォールバック）
    const dataset = event.currentTarget?.dataset
    if (dataset) {
      // キャメルケース
      if (dataset.giftDateSelectorTypeParam) {
        this.debug('Got type from dataset camelCase:', dataset.giftDateSelectorTypeParam)
        return dataset.giftDateSelectorTypeParam
      }
      
      // ケバブケース
      if (dataset['gift-date-selector-type-param']) {
        this.debug('Got type from dataset kebab-case:', dataset['gift-date-selector-type-param'])
        return dataset['gift-date-selector-type-param']
      }
    }
    
    // 方法3: 属性から直接取得
    const typeParam = event.currentTarget?.getAttribute('data-gift-date-selector-type-param')
    if (typeParam) {
      this.debug('Got type from direct attribute:', typeParam)
      return typeParam
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

  // デバッグヘルパー
  debug(...args) {
    if (this.debugValue || this.isDevelopment()) {
      console.log('[GiftDateSelector]', ...args)
    }
  }

  // 開発環境判定
  isDevelopment() {
    return window.location.hostname === 'localhost' || 
           window.location.hostname === '127.0.0.1' ||
           window.location.port === '3000'
  }
}
