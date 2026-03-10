import { Controller } from "@hotwired/stimulus"

// ギフト相手フォームを管理するStimulusコントローラー
// data-controller="gift-person-form" に接続
export default class extends Controller {
  static targets = [
    "input",
    "avatarInput", 
    "avatarPreview", 
    "currentAvatar", 
    "resetButton", 
    "removeCheckbox",
    "memoField",
    "memoCounter",
    "form",
    "submitButton",
    "notificationToggle",
    "notificationSection"
  ]
  
  static values = {
    maxFileSize: { type: Number, default: 10 * 1024 * 1024 }, // ファイルサイズ上限（10MB）
    allowedTypes: { type: Array, default: ["image/jpeg", "image/jpg", "image/png", "image/webp"] }, // 許可する画像形式
    focusColor: { type: String, default: "#FC913A" }, // フォーカス時の枠線色
    blurColor: { type: String, default: "#e1e5e9" }, // 通常時の枠線色
    errorColor: { type: String, default: "#ef4444" }, // エラー時の枠線色
    editMode: { type: Boolean, default: false }, // 編集モードかどうか
    newMode: { type: Boolean, default: false } // 新規作成モードかどうか
  }

  connect() {
    this.setupInputFocusHandling()
    this.setupMemoCounter()
    
    // 編集モード専用の設定
    if (this.editModeValue) {
      this.setupEditMode()
    }
    
    // 新規作成モード専用の設定
    if (this.newModeValue) {
      this.setupNewMode()
    }

    this.updateNotificationSectionVisibility()
  }

  disconnect() {
    // 必要に応じてクリーンアップ処理を実行
  }

  // 全フォーム入力要素のフォーカス・ブラー処理を設定
  setupInputFocusHandling() {
    this.inputTargets.forEach(input => {
      input.addEventListener('focus', this.handleInputFocus.bind(this))
      input.addEventListener('blur', this.handleInputBlur.bind(this))
    })
  }

  handleInputFocus(event) {
    event.target.style.borderColor = this.focusColorValue
  }

  handleInputBlur(event) {
    // 新規作成モードでの名前フィールドのバリデーション
    if (this.newModeValue && event.target.name === 'gift_person[name]') {
      this.validateNameFieldOnBlur(event.target)
    } else {
      event.target.style.borderColor = this.blurColorValue
    }
  }

  // プロフィール画像ファイル選択とプレビュー処理
  avatarSelected(event) {
    const file = event.target.files[0]
    
    if (!file) {
      this.resetAvatarPreview()
      return
    }

    // ファイルサイズの検証
    if (file.size > this.maxFileSizeValue) {
      const mb = Math.round(this.maxFileSizeValue / (1024 * 1024))
      this.showError(`ファイルサイズは${mb}MB以下にしてください。`)
      this.clearAvatarInput()
      return
    }

    // ファイル形式の検証
    if (!this.allowedTypesValue.includes(file.type)) {
      this.showError('JPEG、PNG、WEBP形式のファイルのみアップロードできます。')
      this.clearAvatarInput()
      return
    }

    this.previewAvatar(file)
  }

  previewAvatar(file) {
    const reader = new FileReader()
    
    reader.onload = (e) => {
      // プレビュー画像を表示
      if (this.hasAvatarPreviewTarget) {
        this.avatarPreviewTarget.src = e.target.result
        this.avatarPreviewTarget.style.display = 'block'
      }
      
      // 現在の画像を薄く表示
      if (this.hasCurrentAvatarTarget) {
        this.currentAvatarTarget.style.opacity = '0.3'
      }
      
      // リセットボタンを表示
      if (this.hasResetButtonTarget) {
        this.resetButtonTarget.style.display = 'inline-block'
      }
      
      // 削除チェックボックスがある場合は無効化
      if (this.hasRemoveCheckboxTarget) {
        this.removeCheckboxTarget.checked = false
        this.removeCheckboxTarget.disabled = true
      }
    }
    
    reader.onerror = () => {
      this.showError('ファイルの読み込みに失敗しました。')
      this.clearAvatarInput()
    }
    
    reader.readAsDataURL(file)
  }

  resetAvatarPreview() {
    // ファイル入力をクリア
    this.clearAvatarInput()
    
    // プレビューを非表示
    if (this.hasAvatarPreviewTarget) {
      this.avatarPreviewTarget.src = ''
      this.avatarPreviewTarget.style.display = 'none'
    }
    
    // 現在の画像の透明度を元に戻す
    if (this.hasCurrentAvatarTarget) {
      this.currentAvatarTarget.style.opacity = '1'
    }
    
    // リセットボタンを非表示
    if (this.hasResetButtonTarget) {
      this.resetButtonTarget.style.display = 'none'
    }
    
    // 削除チェックボックスがある場合は再度有効化
    if (this.hasRemoveCheckboxTarget) {
      this.removeCheckboxTarget.disabled = false
    }
  }

  clearAvatarInput() {
    if (this.hasAvatarInputTarget) {
      this.avatarInputTarget.value = ''
    }
  }

  // プロフィール画像削除チェックボックスの処理
  removeAvatarToggled(event) {
    const isChecked = event.target.checked
    
    if (isChecked) {
      // ファイル選択とプレビューをクリア
      this.clearAvatarInput()
      
      if (this.hasAvatarPreviewTarget) {
        this.avatarPreviewTarget.src = ''
        this.avatarPreviewTarget.style.display = 'none'
      }
      
      if (this.hasResetButtonTarget) {
        this.resetButtonTarget.style.display = 'none'
      }
      
      // 削除予定であることを示すために現在の画像を薄く表示
      if (this.hasCurrentAvatarTarget) {
        this.currentAvatarTarget.style.opacity = '0.3'
      }
    } else {
      // 現在の画像の透明度を元に戻す
      if (this.hasCurrentAvatarTarget) {
        this.currentAvatarTarget.style.opacity = '1'
      }
    }
  }

  // メモフィールドの文字数カウンター設定
  setupMemoCounter() {
    if (!this.hasMemoFieldTarget) return
    
    // カウンター要素が存在しない場合は作成
    if (!this.hasMemoCounterTarget) {
      this.createMemoCounter()
    }
    
    this.updateMemoCounter()
  }

  createMemoCounter() {
    const counterDiv = document.createElement('div')
    counterDiv.style.cssText = 'font-size: 11px; color: #999; text-align: right; margin-top: 4px;'
    counterDiv.setAttribute('data-gift-person-form-target', 'memoCounter')
    
    // メモフィールドの後に挿入
    this.memoFieldTarget.parentNode.appendChild(counterDiv)
  }

  memoInput() {
    this.updateMemoCounter()
  }

  updateMemoCounter() {
    if (!this.hasMemoFieldTarget || !this.hasMemoCounterTarget) return
    
    const currentLength = this.memoFieldTarget.value.length
    const maxLength = parseInt(this.memoFieldTarget.getAttribute('maxlength')) || 300
    
    this.memoCounterTarget.textContent = `${currentLength}/${maxLength}文字`
    
    // 使用量に応じて色を変更
    let color = '#999'
    if (currentLength > maxLength * 0.9) {
      color = '#dc3545' // 制限に近い/超えた場合は赤色
    } else if (currentLength > maxLength * 0.8) {
      color = '#ffc107' // 制限に近づいている場合は黄色
    }
    
    this.memoCounterTarget.style.color = color
  }

  // 編集モード専用の初期設定
  setupEditMode() {
    this.originalValues = {}
    
    // 全フォームフィールドの初期値を保存
    this.inputTargets.forEach(field => {
      // チェックボックスの場合は特別な処理
      if (field.type === 'checkbox') {
        this.originalValues[field.name] = field.checked ? '1' : ''
      } else {
        this.originalValues[field.name] = field.value
      }
    })
    
    // フォーム送信イベントリスナーを追加
    if (this.hasFormTarget) {
      this.formTarget.addEventListener('submit', this.handleFormSubmit.bind(this))
    }
  }

  // フォーム送信時の処理
  handleFormSubmit(event) {
    if (!this.editModeValue) return
    
    // 変更があるかチェック
    if (!this.hasFormChanges()) {
      event.preventDefault()
      this.showError('変更がありません。')
      return
    }
    
    // 必須フィールドのバリデーション
    if (!this.validateRequiredFields()) {
      event.preventDefault()
      return
    }
    
    // 送信ボタンを無効化してローディング状態に
    this.setSubmitButtonLoading()
  }

  // フォームに変更があるかチェック
  hasFormChanges() {
    // ファイルフィールドの変更をチェック
    if (this.hasAvatarInputTarget && this.avatarInputTarget.files && this.avatarInputTarget.files.length > 0) {
      return true
    }
    
    return this.inputTargets.some(field => {
      let currentValue
      
      // フィールドタイプに応じて現在の値を取得
      if (field.type === 'checkbox') {
        currentValue = field.checked ? '1' : ''
      } else {
        currentValue = field.value
      }
      
      const originalValue = this.originalValues[field.name] || ''
      
      return currentValue !== originalValue
    })
  }

  // 必須フィールドのバリデーション
  validateRequiredFields() {
    // 名前フィールドの検証
    const nameField = this.inputTargets.find(field => 
      field.name === 'gift_person[name]' || field.id === 'gift_person_name'
    )
    
    if (nameField && !nameField.value.trim()) {
      this.showError('名前を入力してください。')
      nameField.focus()
      return false
    }
    
    // 関係性フィールドの検証
    const relationshipField = this.inputTargets.find(field => 
      field.name === 'gift_person[relationship_id]' || field.id === 'gift_person_relationship_id'
    )
    
    if (relationshipField && !relationshipField.value) {
      this.showError('関係性を選択してください。')
      relationshipField.focus()
      return false
    }
    
    return true
  }

  // 送信ボタンをローディング状態に設定
  setSubmitButtonLoading() {
    if (this.hasSubmitButtonTarget) {
      this.submitButtonTarget.disabled = true
      this.originalSubmitText = this.submitButtonTarget.value
      this.submitButtonTarget.value = '更新中...'
    }
  }

  // 送信ボタンを元の状態に戻す（エラー時等に使用）
  resetSubmitButton() {
    if (this.hasSubmitButtonTarget && this.originalSubmitText) {
      this.submitButtonTarget.disabled = false
      this.submitButtonTarget.value = this.originalSubmitText
    }
  }

  // ユーティリティメソッド
  showError(message) {
    alert(message)
  }

  // 新規作成モード専用の初期設定
  setupNewMode() {
    // フォーム送信イベントリスナーを追加
    if (this.hasFormTarget) {
      this.formTarget.addEventListener('submit', this.handleNewModeFormSubmit.bind(this))
    }
  }

  // 新規作成モードでのフォーム送信処理
  handleNewModeFormSubmit(event) {
    if (!this.newModeValue) return
    
    // 必須フィールドのバリデーション
    if (!this.validateNewModeRequiredFields()) {
      event.preventDefault()
      return
    }
    
    // 送信ボタンをローディング状態に設定
    this.setNewModeSubmitButtonLoading()
  }

  // 新規作成モードでの必須フィールドバリデーション
  validateNewModeRequiredFields() {
    let hasErrors = false
    
    // 名前フィールドの検証
    const nameField = this.inputTargets.find(field => 
      field.name === 'gift_person[name]' || field.id === 'gift_person_name'
    )
    
    if (nameField && !nameField.value.trim()) {
      this.showError('名前を入力してください。')
      nameField.focus()
      hasErrors = true
    }
    
    // 関係性フィールドの検証
    const relationshipField = this.inputTargets.find(field => 
      field.name === 'gift_person[relationship_id]' || field.id === 'gift_person_relationship_id'
    )
    
    if (relationshipField && !relationshipField.value) {
      this.showError('関係性を選択してください。')
      relationshipField.focus()
      hasErrors = true
    }
    
    return !hasErrors
  }

  // 名前フィールドのblurバリデーション
  validateNameFieldOnBlur(field) {
    if (field.value.trim() === '') {
      field.style.borderColor = this.errorColorValue
    } else {
      field.style.borderColor = this.blurColorValue
    }
  }

  // 新規作成モード用の送信ボタンローディング状態
  setNewModeSubmitButtonLoading() {
    if (this.hasSubmitButtonTarget) {
      this.submitButtonTarget.disabled = true
      this.originalSubmitText = this.submitButtonTarget.value
      this.submitButtonTarget.value = '登録中...'
    }
  }

  // 通知設定セクションの表示切り替え
  toggleNotificationSection(event) {
    this.showNotificationSection(event.target.value === 'set')
  }

  updateNotificationSectionVisibility() {
    if (!this.hasNotificationToggleTarget) return
    this.showNotificationSection(this.notificationToggleTarget.value === 'set')
  }

  showNotificationSection(shouldShow) {
    if (!this.hasNotificationSectionTarget) return
    this.notificationSectionTarget.style.display = shouldShow ? 'block' : 'none'
    this.toggleNotificationFieldState(shouldShow)
  }

  toggleNotificationFieldState(shouldEnable) {
    if (!this.hasNotificationSectionTarget) return

    const fields = this.notificationSectionTarget.querySelectorAll('[data-notification-required]')
    fields.forEach(field => {
      if (shouldEnable) {
        if (field.dataset.notificationRequired === 'true') {
          field.setAttribute('required', 'required')
        }
        field.disabled = false
      } else {
        field.removeAttribute('required')
        field.disabled = true
      }
    })
  }
}
