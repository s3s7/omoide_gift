import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "giftPeopleSelect",
    "newGiftPersonFields",
    "publicToggle",
    "toggleLabel",
    "toggleSlider",
    "toggleIcon",
    "toggleStatus",
    "toggleDescription",
    "commentableToggle",
    "commentableToggleLabel",
    "commentableToggleSlider",
    "commentableToggleIcon",
    "commentableToggleStatus",
    "commentableToggleDescription",
    "giftDirectionToggle",
    "giftDirectionToggleLabel",
    "giftDirectionToggleSlider",
    "giftDirectionToggleIcon",
    "giftDirectionToggleStatus",
    "giftDirectionToggleDescription",
    "eventSelect",
    "dateField"
  ]

  static values = {
    showNewFields: String,
    hideNewFields: String
  }

  // 初期化時の処理
  connect() {
    this.initializeGiftPersonFields()
    this.initializeToggleSwitch()
    this.initializeCommentableToggleSwitch()
    this.initializeGiftDirectionToggleSwitch()
    this.initializeFormValidation()
  }

  // 共通: 不要なバブリングを抑止（モバイルでの二重発火対策）
  stopEvent(event) {
    if (event) {
      if (typeof event.stopPropagation === 'function') event.stopPropagation()
      // iOS/Safari でのネイティブ UI 操作時の不意な既定動作抑止は避ける
      // ここでは preventDefault は行わず、バブリングのみ止める
    }
  }

  // ギフト相手選択の初期化
  initializeGiftPersonFields() {
    if (this.hasGiftPeopleSelectTarget && this.hasNewGiftPersonFieldsTarget) {
      this.updateGiftPersonFieldsVisibility()
    }
  }

  // トグルスイッチの初期化
  initializeToggleSwitch() {
    if (this.hasPublicToggleTarget) {
      this.updateToggleUI()
    }
  }

  // コメント設定トグルスイッチの初期化
  initializeCommentableToggleSwitch() {
    if (this.hasCommentableToggleTarget) {
      this.updateCommentableToggleUI()
    }
  }

  // ギフト分類トグルスイッチの初期化
  initializeGiftDirectionToggleSwitch() {
    if (this.hasGiftDirectionToggleTarget) {
      this.updateGiftDirectionToggleUI()
    }
  }

  // フォームバリデーションの初期化
  initializeFormValidation() {
    if (this.hasGiftPeopleSelectTarget) {
      // バリデーションメッセージをクリア
      this.giftPeopleSelectTarget.setCustomValidity('')
    }
  }

  // ギフト相手選択変更時のアクション
  giftPersonChanged() {
    this.updateGiftPersonFieldsVisibility()
    this.clearGiftPersonValidation()
  }

  // ギフト相手フィールドの表示/非表示を更新
  updateGiftPersonFieldsVisibility() {
    if (!this.hasGiftPeopleSelectTarget || !this.hasNewGiftPersonFieldsTarget) {
      return
    }

    const shouldShowFields = this.giftPeopleSelectTarget.value === "new"
    
    if (shouldShowFields) {
      this.newGiftPersonFieldsTarget.style.display = 'block'
    } else {
      this.newGiftPersonFieldsTarget.style.display = 'none'
    }
  }

  // ギフト相手のバリデーションをクリア
  clearGiftPersonValidation() {
    if (this.hasGiftPeopleSelectTarget) {
      this.giftPeopleSelectTarget.setCustomValidity('')
    }
  }

  // トグルスイッチクリック時のアクション
  togglePublicStatus(event) {
    if (!this.hasPublicToggleTarget) return
    // label のデフォルト動作（関連付いた input の自動トグル）を抑止し、
    // 二重トグルによる状態不一致を防ぐ
    if (event && typeof event.preventDefault === 'function') {
      event.preventDefault()
      // 念のためバブリングも止める（他のクリックハンドラへの影響を防止）
      if (typeof event.stopPropagation === 'function') {
        event.stopPropagation()
      }
    }

    this.publicToggleTarget.checked = !this.publicToggleTarget.checked
    this.updateToggleUI()
  }

  // コメント設定トグルスイッチクリック時のアクション
  toggleCommentableStatus(event) {
    if (!this.hasCommentableToggleTarget) return
    // label のデフォルト動作（関連付いた input の自動トグル）を抑止し、
    // 二重トグルによる状態不一致を防ぐ
    if (event && typeof event.preventDefault === 'function') {
      event.preventDefault()
      // 念のためバブリングも止める（他のクリックハンドラへの影響を防止）
      if (typeof event.stopPropagation === 'function') {
        event.stopPropagation()
      }
    }

    this.commentableToggleTarget.checked = !this.commentableToggleTarget.checked
    this.updateCommentableToggleUI()
  }

  // ギフト分類トグルスイッチクリック時のアクション
  toggleGiftDirectionStatus(event) {
    if (!this.hasGiftDirectionToggleTarget) return
    // label のデフォルト動作（関連付いた input の自動トグル）を抑止し、
    // 二重トグルによる状態不一致を防ぐ
    if (event && typeof event.preventDefault === 'function') {
      event.preventDefault()
      // 念のためバブリングも止める（他のクリックハンドラへの影響を防止）
      if (typeof event.stopPropagation === 'function') {
        event.stopPropagation()
      }
    }

    this.giftDirectionToggleTarget.checked = !this.giftDirectionToggleTarget.checked
    this.updateGiftDirectionToggleUI()
  }

  // トグルスイッチのUI更新
  updateToggleUI() {
    if (!this.hasPublicToggleTarget) return

    const isPublic = this.publicToggleTarget.checked

    // ラベルとスライダーの更新
    if (this.hasToggleLabelTarget && this.hasToggleSliderTarget) {
      if (isPublic) {
        this.toggleLabelTarget.style.backgroundColor = '#28a745'
        this.toggleSliderTarget.style.transform = 'translateX(26px)'
      } else {
        this.toggleLabelTarget.style.backgroundColor = '#6c757d'
        this.toggleSliderTarget.style.transform = 'translateX(0)'
      }
    }

    // アイコンとテキストの更新
    if (this.hasToggleIconTarget && this.hasToggleStatusTarget) {
      if (isPublic) {
        this.toggleIconTarget.className = 'fas fa-globe'
        this.toggleIconTarget.style.color = '#28a745'
        this.toggleStatusTarget.textContent = '公開'
      } else {
        this.toggleIconTarget.className = 'fas fa-lock'
        this.toggleIconTarget.style.color = '#6c757d'
        this.toggleStatusTarget.textContent = '非公開'
      }
    }

    // 説明テキストの更新
    if (this.hasToggleDescriptionTarget) {
      if (isPublic) {
        this.toggleDescriptionTarget.textContent = '他のユーザーがこのギフト記録を見ることができます'
      } else {
        this.toggleDescriptionTarget.textContent = 'あなただけがこのギフト記録を見ることができます'
      }
    }
  }

  // コメント設定トグルスイッチのUI更新
  updateCommentableToggleUI() {
    if (!this.hasCommentableToggleTarget) return

    const isCommentable = this.commentableToggleTarget.checked

    // ラベルとスライダーの更新
    if (this.hasCommentableToggleLabelTarget && this.hasCommentableToggleSliderTarget) {
      if (isCommentable) {
        this.commentableToggleLabelTarget.style.backgroundColor = '#007bff'
        this.commentableToggleSliderTarget.style.transform = 'translateX(26px)'
      } else {
        this.commentableToggleLabelTarget.style.backgroundColor = '#6c757d'
        this.commentableToggleSliderTarget.style.transform = 'translateX(0)'
      }
    }

    // アイコンとテキストの更新
    if (this.hasCommentableToggleIconTarget && this.hasCommentableToggleStatusTarget) {
      if (isCommentable) {
        this.commentableToggleIconTarget.className = 'fas fa-comments'
        this.commentableToggleIconTarget.style.color = '#007bff'
        this.commentableToggleStatusTarget.textContent = 'コメント可能'
      } else {
        this.commentableToggleIconTarget.className = 'fas fa-comment-slash'
        this.commentableToggleIconTarget.style.color = '#6c757d'
        this.commentableToggleStatusTarget.textContent = 'コメント無効'
      }
    }

    // 説明テキストの更新
    if (this.hasCommentableToggleDescriptionTarget) {
      if (isCommentable) {
        this.commentableToggleDescriptionTarget.textContent = '他のユーザーがこのギフト記録にコメントできます'
      } else {
        this.commentableToggleDescriptionTarget.textContent = '他のユーザーはこのギフト記録にコメントできません'
      }
    }
  }

  // ギフト分類トグルスイッチのUI更新
  updateGiftDirectionToggleUI() {
    if (!this.hasGiftDirectionToggleTarget) return

    const isReceived = this.giftDirectionToggleTarget.checked

    // ラベルとスライダーの更新
    if (this.hasGiftDirectionToggleLabelTarget && this.hasGiftDirectionToggleSliderTarget) {
      if (isReceived) {
        this.giftDirectionToggleLabelTarget.style.backgroundColor = '#FF6B6B'
        this.giftDirectionToggleSliderTarget.style.transform = 'translateX(0)'
      } else {
        this.giftDirectionToggleLabelTarget.style.backgroundColor = '#28a745'
        this.giftDirectionToggleSliderTarget.style.transform = 'translateX(26px)'
      }
    }

    // アイコンとテキストの更新
    if (this.hasGiftDirectionToggleIconTarget && this.hasGiftDirectionToggleStatusTarget) {
      if (isReceived) {
        this.giftDirectionToggleIconTarget.className = 'fas fa-hand-holding-heart'
        this.giftDirectionToggleIconTarget.style.color = '#FF6B6B'
        this.giftDirectionToggleStatusTarget.textContent = 'もらったギフト'
      } else {
        this.giftDirectionToggleIconTarget.className = 'fas fa-gift'
        this.giftDirectionToggleIconTarget.style.color = '#28a745'
        this.giftDirectionToggleStatusTarget.textContent = '贈ったギフト'
      }
    }

    // 説明テキストの更新
    if (this.hasGiftDirectionToggleDescriptionTarget) {
      if (isReceived) {
        this.giftDirectionToggleDescriptionTarget.textContent = 'あなたが受け取ったギフトを記録します'
      } else {
        this.giftDirectionToggleDescriptionTarget.textContent = 'あなたが贈ったギフトを記録します'
      }
    }
  }

  // イベント選択のクイック設定
  setEventSelection(event) {
    const eventId = event.params.eventId
    if (this.hasEventSelectTarget && eventId) {
      this.eventSelectTarget.value = eventId
    }
  }

  // 日付のクイック設定
  setGiftDate(event) {
    const dateType = event.params.dateType
    if (!this.hasDateFieldTarget || !dateType) return

    const today = new Date()
    let targetDate

    switch(dateType) {
      case 'today':
        targetDate = today
        break
      case 'yesterday':
        targetDate = new Date(today)
        targetDate.setDate(today.getDate() - 1)
        break
      case 'week_ago':
        targetDate = new Date(today)
        targetDate.setDate(today.getDate() - 7)
        break
      default:
        targetDate = today
    }

    this.dateFieldTarget.value = targetDate.toISOString().split('T')[0]
  }

  // フォーム送信時のバリデーション
  validateForm(event) {
    // ギフト相手が選択されていない場合
    if (this.hasGiftPeopleSelectTarget && 
        (!this.giftPeopleSelectTarget.value || this.giftPeopleSelectTarget.value === '')) {
      event.preventDefault()
      
      this.giftPeopleSelectTarget.setCustomValidity('このフィールドを入力してください')
      this.giftPeopleSelectTarget.reportValidity()
      this.giftPeopleSelectTarget.focus()
      
      return false
    }

    return true
  }

  // デバッグ用：現在の状態を出力
  debug() {
    return {
      giftPersonVisible: this.hasNewGiftPersonFieldsTarget ? 
        this.newGiftPersonFieldsTarget.style.display !== 'none' : false,
      publicToggleChecked: this.hasPublicToggleTarget ? 
        this.publicToggleTarget.checked : null,
      selectedGiftPerson: this.hasGiftPeopleSelectTarget ? 
        this.giftPeopleSelectTarget.value : null
    }
  }
}
