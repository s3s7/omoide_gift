import { Controller } from "@hotwired/stimulus"

// ユーザープロフィール編集フォームを管理するStimulusコントローラー
// data-controller="user-form" に接続
export default class extends Controller {
  static targets = [
    "form",
    "input", // テキストフィールド・メールフィールド
    "avatarInput",
    "avatarPreview", 
    "currentAvatar",
    "resetAvatarButton",
    "removeAvatarCheckbox",
    "cancelButton",
    "submitButton"
  ]
  
  static values = {
    maxFileSize: { type: Number, default: 5242880 }, // ファイルサイズ上限（5MB）
    allowedTypes: { type: Array, default: ["image/jpeg", "image/jpg", "image/png", "image/webp"] } // 許可する画像形式
  }

  connect() {
    // フォームの初期値を保存
    this.storeInitialValues()
    
    // 変更検知の初期化
    this.hasUnsavedChanges = false
    this.setupChangeDetection()
    
    // ページを離れる前の警告設定
    this.setupBeforeUnloadWarning()
  }

  disconnect() {
    // イベントリスナーのクリーンアップ
    if (this.beforeUnloadHandler) {
      window.removeEventListener('beforeunload', this.beforeUnloadHandler)
    }
  }

  // フォームの初期値を保存
  storeInitialValues() {
    this.initialValues = {}
    
    this.inputTargets.forEach(input => {
      this.initialValues[input.name] = input.value
    })
  }

  // 変更検知の設定
  setupChangeDetection() {
    this.inputTargets.forEach(input => {
      input.addEventListener('input', this.handleInputChange.bind(this))
    })
  }

  // 入力値変更時の処理
  handleInputChange(event) {
    const field = event.target
    this.hasUnsavedChanges = (field.value !== this.initialValues[field.name])
  }

  // ページを離れる前の警告設定
  setupBeforeUnloadWarning() {
    this.beforeUnloadHandler = (e) => {
      if (this.hasUnsavedChanges) {
        e.preventDefault()
        e.returnValue = '変更が保存されていません。ページを離れますか？'
        return e.returnValue
      }
    }
    
    window.addEventListener('beforeunload', this.beforeUnloadHandler)
  }

  // プロフィール画像選択時の処理
  avatarSelected(event) {
    const file = event.target.files[0]
    
    if (!file) {
      this.resetAvatarPreview()
      return
    }

    // ファイルサイズの検証
    if (file.size > this.maxFileSizeValue) {
      this.showError('ファイルサイズは5MB以下にしてください。')
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

  // プロフィール画像のプレビュー表示
  previewAvatar(file) {
    const reader = new FileReader()
    
    reader.onload = (e) => {
      // プレビュー画像を表示
      if (this.hasAvatarPreviewTarget) {
        this.avatarPreviewTarget.src = e.target.result
        this.avatarPreviewTarget.classList.remove('hidden')
      }
      
      // 現在の画像を薄く表示
      if (this.hasCurrentAvatarTarget) {
        this.currentAvatarTarget.style.opacity = '0.3'
      }
      
      // リセットボタンを表示
      if (this.hasResetAvatarButtonTarget) {
        this.resetAvatarButtonTarget.classList.remove('hidden')
      }
      
      // 削除チェックボックスがある場合は無効化
      if (this.hasRemoveAvatarCheckboxTarget) {
        this.removeAvatarCheckboxTarget.checked = false
        this.removeAvatarCheckboxTarget.disabled = true
      }
      
      this.hasUnsavedChanges = true
    }
    
    reader.onerror = () => {
      this.showError('ファイルの読み込みに失敗しました。')
      this.clearAvatarInput()
    }
    
    reader.readAsDataURL(file)
  }

  // プロフィール画像プレビューのリセット
  resetAvatarPreview() {
    // ファイル入力をクリア
    this.clearAvatarInput()
    
    // プレビューを非表示
    if (this.hasAvatarPreviewTarget) {
      this.avatarPreviewTarget.src = ''
      this.avatarPreviewTarget.classList.add('hidden')
    }
    
    // 現在の画像の透明度を元に戻す
    if (this.hasCurrentAvatarTarget) {
      this.currentAvatarTarget.style.opacity = '1'
    }
    
    // リセットボタンを非表示
    if (this.hasResetAvatarButtonTarget) {
      this.resetAvatarButtonTarget.classList.add('hidden')
    }
    
    // 削除チェックボックスを有効化
    if (this.hasRemoveAvatarCheckboxTarget) {
      this.removeAvatarCheckboxTarget.disabled = false
    }
  }

  // ファイル入力のクリア
  clearAvatarInput() {
    if (this.hasAvatarInputTarget) {
      this.avatarInputTarget.value = ''
    }
  }

  // プロフィール画像削除チェックボックスの処理
  removeAvatarToggled(event) {
    const isChecked = event.target.checked
    
    if (isChecked) {
      // プレビューをリセット
      this.clearAvatarInput()
      
      if (this.hasAvatarPreviewTarget) {
        this.avatarPreviewTarget.src = ''
        this.avatarPreviewTarget.classList.add('hidden')
      }
      
      if (this.hasResetAvatarButtonTarget) {
        this.resetAvatarButtonTarget.classList.add('hidden')
      }
      
      // 削除予定であることを示すため現在の画像を薄く表示
      if (this.hasCurrentAvatarTarget) {
        this.currentAvatarTarget.style.opacity = '0.3'
      }
      
      this.hasUnsavedChanges = true
    } else {
      // 現在の画像の透明度を元に戻す
      if (this.hasCurrentAvatarTarget) {
        this.currentAvatarTarget.style.opacity = '1'
      }
    }
  }

  // フォーム全体のリセット
  resetForm() {
    if (!confirm('入力内容をリセットしますか？未保存の変更は失われます。')) {
      return
    }

    // テキストフィールドのリセット
    this.inputTargets.forEach(input => {
      input.value = this.initialValues[input.name] || ''
    })
    
    // プロフィール画像のリセット
    this.clearAvatarInput()
    
    if (this.hasAvatarPreviewTarget) {
      this.avatarPreviewTarget.src = ''
      this.avatarPreviewTarget.classList.add('hidden')
    }
    
    if (this.hasCurrentAvatarTarget) {
      this.currentAvatarTarget.style.opacity = '1'
    }
    
    if (this.hasResetAvatarButtonTarget) {
      this.resetAvatarButtonTarget.classList.add('hidden')
    }
    
    if (this.hasRemoveAvatarCheckboxTarget) {
      this.removeAvatarCheckboxTarget.checked = false
      this.removeAvatarCheckboxTarget.disabled = false
    }
    
    this.hasUnsavedChanges = false
  }

  // キャンセルボタンクリック時の確認
  cancelClicked(event) {
    if (this.hasUnsavedChanges) {
      if (!confirm('変更が保存されていません。マイページに戻りますか？')) {
        event.preventDefault()
      }
    }
  }

  // フォーム送信時の処理
  formSubmitted() {
    // 送信時は未保存変更の警告を無効化
    this.hasUnsavedChanges = false
  }

  // エラーメッセージ表示
  showError(message) {
    // 現在はブラウザのalertを使用、将来的にはより良いUIに変更可能
    alert(message)
  }
}