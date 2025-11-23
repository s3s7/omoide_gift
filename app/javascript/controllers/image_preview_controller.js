import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "dropZone", 
    "fileInput", 
    "uploadPrompt", 
    "previewContainer", 
    "previewGrid", 
    "imageCount",
    "deleteImageContainer",
    "existingImagesContainer",
    "existingImageCount",
    "existingImagesGrid",
    "existingImageItem",
    "restoreAllButton"
  ]

  static values = {
    maxFiles: { type: Number, default: 5 },
    maxSize: { type: Number, default: 5 * 1024 * 1024 }, // 5MB
    acceptedTypes: { type: Array, default: ["image/jpeg", "image/jpg", "image/png", "image/webp"] }
  }

  connect() {
    this.selectedFiles = []
    this.objectUrls = [] // メモリリーク防止のためURLを管理
    this.deleteImageIds = [] // 削除対象の既存画像IDを管理
    
    // キーボードアクセシビリティ
    this.dropZoneTarget.addEventListener('keydown', this.handleKeyDown.bind(this))
    
    // フォーム送信前に隠しフィールドを確実に設定
    const form = this.element.closest('form')
    if (form) {
      form.addEventListener('submit', (event) => {
        this.updateDeleteImageIds()  // 送信前に最新の削除IDを反映
      })
    }
  }

  disconnect() {
    // メモリリーク防止: オブジェクトURLを解放
    this.cleanupObjectUrls()
  }

  // ドラッグオーバー処理
  dragOver(event) {
    event.preventDefault()
    event.stopPropagation()
    
    this.dropZoneTarget.classList.remove('border-gray-300', 'bg-gray-50')
    this.dropZoneTarget.classList.add('border-orange-400', 'bg-orange-50', 'border-solid')
  }

  // ドラッグリーブ処理
  dragLeave(event) {
    event.preventDefault()
    event.stopPropagation()
    
    // 子要素からのイベントは無視
    if (!this.dropZoneTarget.contains(event.relatedTarget)) {
      this.resetDropZoneStyle()
    }
  }

  // ドロップ処理
  drop(event) {
    event.preventDefault()
    event.stopPropagation()
    
    this.resetDropZoneStyle()
    
    const files = Array.from(event.dataTransfer.files)
    this.handleFiles(files)
  }

  // クリック処理
  clickInput() {
    this.fileInputTarget.click()
  }

  // キーボード処理
  handleKeyDown(event) {
    if (event.key === 'Enter' || event.key === ' ') {
      event.preventDefault()
      this.clickInput()
    }
  }

  // ファイル選択処理
  previewImages(event) {
    const files = Array.from(event.target.files)
    this.handleFiles(files)
  }

  // ファイル処理のメイン関数
  handleFiles(files) {
    // 既存ファイルと新規ファイルの合計チェック
    const totalFiles = this.selectedFiles.length + files.length
    
    if (totalFiles > this.maxFilesValue) {
      this.showError(`画像は最大${this.maxFilesValue}枚まで選択できます`)
      this.resetFileInput()
      this.updateFileInput()
      this.updatePreview()
      return
    }

    // まず全ファイルを検証（1つでもエラーなら全体を拒否）
    const errors = []
    const validFiles = []
    for (const file of files) {
      const displayIndex = this.selectedFiles.length + validFiles.length + 1
      const validation = this.validateFile(file, displayIndex)
      if (!validation.valid) {
        errors.push(validation.error)
      }
      validFiles.push(file)
    }

    if (errors.length > 0) {
      // 先頭のエラーを表示（ギフト相手フォームと同様の挙動）
      this.showError(errors[0])
      this.resetFileInput()
      this.updateFileInput()
      this.updatePreview()
      return
    }

    if (validFiles.length > 0) {
      this.selectedFiles = [...this.selectedFiles, ...validFiles]
      this.updateFileInput()
      this.updatePreview()
      this.clearErrors()
    }
  }

  // ファイル検証
  validateFile(file, displayIndex = null) {
    const prefix = displayIndex ? `${displayIndex}枚目: ` : ""

    // ファイル形式チェック
    if (!this.acceptedTypesValue.includes(file.type)) {
      return {
        valid: false,
        error: `${prefix}JPEG、PNG、WEBP形式のファイルのみアップロードできます`
      }
    }

    // ファイルサイズチェック
    if (file.size > this.maxSizeValue) {
      const maxSizeMB = Math.round(this.maxSizeValue / (1024 * 1024))
      return {
        valid: false,
        error: `${prefix}ファイルサイズは${maxSizeMB}MB以下にしてください`
      }
    }

    return { valid: true }
  }

  // プレビュー更新
  updatePreview() {
    this.previewGridTarget.innerHTML = ''
    this.cleanupObjectUrls()

    this.selectedFiles.forEach((file, index) => {
      const objectUrl = URL.createObjectURL(file)
      this.objectUrls.push(objectUrl)

      const previewItem = this.createPreviewItem(file, objectUrl, index)
      this.previewGridTarget.appendChild(previewItem)
    })

    // プレビューコンテナの表示/非表示
    if (this.selectedFiles.length > 0) {
      this.previewContainerTarget.classList.remove('hidden')
      this.imageCountTarget.textContent = this.selectedFiles.length
    } else {
      this.previewContainerTarget.classList.add('hidden')
    }
  }

  // プレビューアイテム作成
  createPreviewItem(file, objectUrl, index) {
    const div = document.createElement('div')
    div.className = 'relative group'
    
    div.innerHTML = `
      <div class="aspect-square rounded-lg overflow-hidden bg-gray-100 border-2 border-gray-200">
        <img src="${objectUrl}" 
             alt="${file.name}" 
             class="w-full h-full object-cover">
      </div>
      <div class="absolute top-1 right-1 opacity-0 group-hover:opacity-100 transition-opacity duration-200">
        <button type="button" 
                class="w-6 h-6 bg-red-500 hover:bg-red-600 text-white text-xs rounded-full flex items-center justify-center shadow-lg transition-colors duration-200"
                data-action="click->image-preview#removeFile"
                data-index="${index}"
                aria-label="画像を削除">
          <i class="fas fa-times"></i>
        </button>
      </div>
      <div class="mt-1 text-xs text-gray-500 truncate" title="${file.name}">
        ${file.name}
      </div>
    `
    
    return div
  }

  // ファイル削除
  removeFile(event) {
    const index = parseInt(event.currentTarget.dataset.index)
    
    // オブジェクトURL解放
    if (this.objectUrls[index]) {
      URL.revokeObjectURL(this.objectUrls[index])
    }
    
    this.selectedFiles.splice(index, 1)
    this.updateFileInput()
    this.updatePreview()
  }

  // 全ファイルクリア
  clearAll() {
    this.selectedFiles = []
    this.cleanupObjectUrls()
    this.updateFileInput()
    this.updatePreview()
    this.clearErrors()
  }

  // FileInputの更新
  updateFileInput() {
    // DataTransferを使用してFileListを再構築
    const dataTransfer = new DataTransfer()
    this.selectedFiles.forEach(file => dataTransfer.items.add(file))
    this.fileInputTarget.files = dataTransfer.files
  }

  resetFileInput() {
    this.fileInputTarget.value = ""
  }

  // ドロップゾーンスタイルリセット
  resetDropZoneStyle() {
    this.dropZoneTarget.classList.remove('border-orange-400', 'bg-orange-50', 'border-solid')
    this.dropZoneTarget.classList.add('border-gray-300', 'bg-gray-50')
  }

  // エラー表示
  showError(message) {
    alert(message)
  }

  // エラークリア
  clearErrors() {
    const errorContainer = this.element.querySelector('.client-error-message')
    if (errorContainer) {
      errorContainer.remove()
    }
  }

  // オブジェクトURL解放
  cleanupObjectUrls() {
    this.objectUrls.forEach(url => URL.revokeObjectURL(url))
    this.objectUrls = []
  }

  // === 既存画像削除機能 ===

  // 既存画像を削除（見た目上）
  deleteExistingImage(event) {
    const imageId = event.currentTarget.dataset.imageId
    const imageItem = event.currentTarget.closest('[data-image-preview-target="existingImageItem"]')
    
    if (imageId && imageItem) {
      // 削除対象IDに追加
      if (!this.deleteImageIds.includes(imageId)) {
        this.deleteImageIds.push(imageId)
        this.updateDeleteImageIds()
      }
      
      // 見た目上削除（非表示にする）
      imageItem.style.opacity = '0.3'
      imageItem.style.filter = 'grayscale(100%)'
      imageItem.classList.add('deleted-image')
      
      // 削除ボタンを復元ボタンに変更
      const deleteButton = imageItem.querySelector('button')
      if (deleteButton) {
        deleteButton.innerHTML = '<i class="fas fa-undo"></i>'
        deleteButton.className = 'w-6 h-6 bg-green-500 hover:bg-green-600 text-white text-xs rounded-full flex items-center justify-center shadow-lg transition-colors duration-200'
        deleteButton.setAttribute('data-action', 'click->image-preview#restoreExistingImage')
        deleteButton.setAttribute('aria-label', '画像を復元')
      }
      
      this.updateExistingImageCount()
      this.toggleRestoreAllButton()
    }
  }

  // 既存画像を復元（個別）
  restoreExistingImage(event) {
    const imageId = event.currentTarget.dataset.imageId
    const imageItem = event.currentTarget.closest('[data-image-preview-target="existingImageItem"]')
    
    if (imageId && imageItem) {
      // 削除対象IDから除去
      const index = this.deleteImageIds.indexOf(imageId)
      if (index > -1) {
        this.deleteImageIds.splice(index, 1)
        this.updateDeleteImageIds()
      }
      
      // 見た目を復元
      imageItem.style.opacity = '1'
      imageItem.style.filter = 'none'
      imageItem.classList.remove('deleted-image')
      
      // 復元ボタンを削除ボタンに戻す
      const restoreButton = imageItem.querySelector('button')
      if (restoreButton) {
        restoreButton.innerHTML = '<i class="fas fa-times"></i>'
        restoreButton.className = 'w-6 h-6 bg-red-500 hover:bg-red-600 text-white text-xs rounded-full flex items-center justify-center shadow-lg transition-colors duration-200'
        restoreButton.setAttribute('data-action', 'click->image-preview#deleteExistingImage')
        restoreButton.setAttribute('aria-label', '画像を削除')
      }
      
      this.updateExistingImageCount()
      this.toggleRestoreAllButton()
    }
  }

  // すべての既存画像を復元
  restoreAllExistingImages() {
    const deletedItems = this.existingImagesGridTarget.querySelectorAll('.deleted-image')
    
    deletedItems.forEach(item => {
      const imageId = item.dataset.imageId
      if (imageId) {
        // 削除対象IDから除去
        const index = this.deleteImageIds.indexOf(imageId)
        if (index > -1) {
          this.deleteImageIds.splice(index, 1)
        }
        
        // 見た目を復元
        item.style.opacity = '1'
        item.style.filter = 'none'
        item.classList.remove('deleted-image')
        
        // 復元ボタンを削除ボタンに戻す
        const restoreButton = item.querySelector('button')
        if (restoreButton) {
          restoreButton.innerHTML = '<i class="fas fa-times"></i>'
          restoreButton.className = 'w-6 h-6 bg-red-500 hover:bg-red-600 text-white text-xs rounded-full flex items-center justify-center shadow-lg transition-colors duration-200'
          restoreButton.setAttribute('data-action', 'click->image-preview#deleteExistingImage')
          restoreButton.setAttribute('aria-label', '画像を削除')
        }
      }
    })
    
    this.updateDeleteImageIds()
    this.updateExistingImageCount()
    this.toggleRestoreAllButton()
  }

  // 削除対象IDを隠しフィールドに反映
  updateDeleteImageIds() {
    // deleteImageContainerTargetが存在するかチェック
    if (!this.hasDeleteImageContainerTarget) {
      console.error('deleteImageContainer target not found')
      return
    }
    
    // 既存の隠しフィールドをクリア
    this.deleteImageContainerTarget.innerHTML = ''
    
    // 削除対象IDがある場合のみ隠しフィールドを作成
    this.deleteImageIds.forEach(imageId => {
      
      const hiddenField = document.createElement('input')
      hiddenField.type = 'hidden'
      hiddenField.name = 'gift_record[delete_image_ids][]'
      hiddenField.value = imageId
      
      // デバッグ用の属性を追加
      hiddenField.setAttribute('data-debug', 'delete-image-id')
      
      this.deleteImageContainerTarget.appendChild(hiddenField)
    })
    
    // 作成された隠しフィールドの確認
    const createdFields = this.deleteImageContainerTarget.querySelectorAll('input[type="hidden"]')
  }

  // 既存画像数表示を更新
  updateExistingImageCount() {
    if (this.hasExistingImageCountTarget) {
      const totalImages = this.existingImageItemTargets.length
      const deletedImages = this.deleteImageIds.length
      const remainingImages = totalImages - deletedImages
      
      this.existingImageCountTarget.textContent = remainingImages
    }
  }

  // 「すべて復元」ボタンの表示/非表示を切り替え
  toggleRestoreAllButton() {
    if (this.hasRestoreAllButtonTarget) {
      if (this.deleteImageIds.length > 0) {
        this.restoreAllButtonTarget.classList.remove('hidden')
      } else {
        this.restoreAllButtonTarget.classList.add('hidden')
      }
    }
  }
}
