import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "dropZone", 
    "fileInput", 
    "uploadPrompt", 
    "previewContainer", 
    "previewGrid", 
    "imageCount"
  ]

  static values = {
    maxFiles: { type: Number, default: 5 },
    maxSize: { type: Number, default: 10 * 1024 * 1024 }, // 10MB
    acceptedTypes: { type: Array, default: ["image/jpeg", "image/jpg", "image/png", "image/webp"] }
  }

  connect() {
    this.selectedFiles = []
    this.objectUrls = [] // メモリリーク防止のためURLを管理
    
    // キーボードアクセシビリティ
    this.dropZoneTarget.addEventListener('keydown', this.handleKeyDown.bind(this))
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
      return
    }

    // ファイル検証と追加
    const validFiles = []
    for (const file of files) {
      const validation = this.validateFile(file)
      if (validation.valid) {
        validFiles.push(file)
      } else {
        this.showError(validation.error)
      }
    }

    if (validFiles.length > 0) {
      this.selectedFiles = [...this.selectedFiles, ...validFiles]
      this.updateFileInput()
      this.updatePreview()
      this.clearErrors()
    }
  }

  // ファイル検証
  validateFile(file) {
    // ファイル形式チェック
    if (!this.acceptedTypesValue.includes(file.type)) {
      return {
        valid: false,
        error: `${file.name}: サポートされていないファイル形式です (JPEG、PNG、WEBP のみ)`
      }
    }

    // ファイルサイズチェック
    if (file.size > this.maxSizeValue) {
      const maxSizeMB = Math.floor(this.maxSizeValue / (1024 * 1024))
      return {
        valid: false,
        error: `${file.name}: ファイルサイズが大きすぎます (最大${maxSizeMB}MB)`
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

  // ドロップゾーンスタイルリセット
  resetDropZoneStyle() {
    this.dropZoneTarget.classList.remove('border-orange-400', 'bg-orange-50', 'border-solid')
    this.dropZoneTarget.classList.add('border-gray-300', 'bg-gray-50')
  }

  // エラー表示
  showError(message) {
    // 既存のエラーメッセージ領域を探す
    let errorContainer = this.element.querySelector('.client-error-message')
    
    if (!errorContainer) {
      errorContainer = document.createElement('div')
      errorContainer.className = 'client-error-message text-red-600 text-xs mt-2'
      errorContainer.setAttribute('role', 'alert')
      
      // ヘルプテキストの後に挿入
      const helpText = this.element.querySelector('#image_upload_help')
      helpText.parentNode.insertBefore(errorContainer, helpText.nextSibling)
    }
    
    errorContainer.innerHTML = `
      <i class="fas fa-exclamation-triangle mr-1"></i>
      ${message}
    `
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
}