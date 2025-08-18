import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["modal", "modalImage", "imageInfo", "prevButton", "nextButton"]

  connect() {
    this.currentIndex = 0
    this.images = []
    this.isOpen = false
    
    // 画像URLを事前に準備
    this.prepareImages()
    
    // ESCキーでモーダルを閉じる
    this.boundHandleKeydown = this.handleKeydown.bind(this)
    document.addEventListener('keydown', this.boundHandleKeydown)
  }

  disconnect() {
    document.removeEventListener('keydown', this.boundHandleKeydown)
    
    // Body scroll の復元
    if (this.isOpen) {
      document.body.style.overflow = ''
    }
  }

  // 画像データの準備
  prepareImages() {
    const imageElements = this.element.querySelectorAll('[data-index]')
    this.images = Array.from(imageElements).map((el, index) => {
      const img = el.querySelector('img')
      return {
        index: index,
        thumbnailSrc: img.src,
        fullSrc: this.getFullSizeImageUrl(img.src),
        alt: img.alt || `ギフト画像 ${index + 1}`
      }
    })
  }

  // フルサイズ画像URLを生成（Active Storageのvariant URLから）
  getFullSizeImageUrl(thumbnailUrl) {
    // thumbnail URLからvariant部分を削除してオリジナルサイズを取得
    // 例: /rails/active_storage/representations/redirect/xxx/xxx/xxx.jpg
    // → より大きなサイズのvariantに変更
    if (thumbnailUrl.includes('/representations/')) {
      // より大きなサイズ（800x800）に変更
      return thumbnailUrl.replace(/\/representations\/[^\/]+\/[^\/]+\//, '/representations/redirect/')
        .replace(/\?.*$/, '?variation=800x800')
    }
    return thumbnailUrl
  }

  // モーダルを開く
  openModal(event) {
    event.preventDefault()
    event.stopPropagation()
    
    const clickedElement = event.currentTarget
    this.currentIndex = parseInt(clickedElement.dataset.index)
    
    this.showModal()
    this.loadCurrentImage()
    this.updateNavigation()
    this.updateImageInfo()
  }

  // モーダルを閉じる
  closeModal(event) {
    // モーダル内の画像をクリックした場合は閉じない
    if (event && event.target === this.modalImageTarget) {
      return
    }
    
    this.hideModal()
  }

  // 前の画像
  previousImage(event) {
    event.preventDefault()
    event.stopPropagation()
    
    if (this.images.length <= 1) return
    
    this.currentIndex = this.currentIndex > 0 ? this.currentIndex - 1 : this.images.length - 1
    this.loadCurrentImage()
    this.updateNavigation()
    this.updateImageInfo()
  }

  // 次の画像
  nextImage(event) {
    event.preventDefault()
    event.stopPropagation()
    
    if (this.images.length <= 1) return
    
    this.currentIndex = this.currentIndex < this.images.length - 1 ? this.currentIndex + 1 : 0
    this.loadCurrentImage()
    this.updateNavigation()
    this.updateImageInfo()
  }

  // キーボードイベント処理
  handleKeydown(event) {
    if (!this.isOpen) return

    switch(event.key) {
      case 'Escape':
        event.preventDefault()
        this.hideModal()
        break
      case 'ArrowLeft':
        event.preventDefault()
        this.previousImage(event)
        break
      case 'ArrowRight':
        event.preventDefault()
        this.nextImage(event)
        break
    }
  }

  // モーダル表示
  showModal() {
    this.modalTarget.classList.remove('hidden')
    this.modalTarget.classList.add('flex')
    
    // Body scrollを無効化
    document.body.style.overflow = 'hidden'
    this.isOpen = true
    
    // フォーカス管理
    this.modalTarget.focus()
    
    // アニメーション
    setTimeout(() => {
      this.modalTarget.style.opacity = '1'
    }, 10)
  }

  // モーダル非表示
  hideModal() {
    this.modalTarget.style.opacity = '0'
    
    setTimeout(() => {
      this.modalTarget.classList.remove('flex')
      this.modalTarget.classList.add('hidden')
      
      // Body scrollを復元
      document.body.style.overflow = ''
      this.isOpen = false
    }, 200)
  }

  // 現在の画像を読み込み
  loadCurrentImage() {
    const currentImage = this.images[this.currentIndex]
    if (!currentImage) return

    // ローディング状態表示
    this.modalImageTarget.style.opacity = '0.5'
    
    // 新しい画像を読み込み
    const img = new Image()
    img.onload = () => {
      this.modalImageTarget.src = img.src
      this.modalImageTarget.alt = currentImage.alt
      this.modalImageTarget.style.opacity = '1'
    }
    
    img.onerror = () => {
      // エラー時はサムネイル画像を使用
      this.modalImageTarget.src = currentImage.thumbnailSrc
      this.modalImageTarget.alt = currentImage.alt
      this.modalImageTarget.style.opacity = '1'
    }
    
    img.src = currentImage.fullSrc
  }

  // ナビゲーションボタンの更新
  updateNavigation() {
    if (this.images.length <= 1) return

    // 前ボタンの状態
    if (this.hasPrevButtonTarget) {
      this.prevButtonTarget.style.opacity = this.currentIndex > 0 ? '1' : '0.5'
    }
    
    // 次ボタンの状態
    if (this.hasNextButtonTarget) {
      this.nextButtonTarget.style.opacity = this.currentIndex < this.images.length - 1 ? '1' : '0.5'
    }
  }

  // 画像情報の更新
  updateImageInfo() {
    if (this.hasImageInfoTarget) {
      this.imageInfoTarget.textContent = `画像 ${this.currentIndex + 1} / ${this.images.length}`
    }
  }

  // ユーティリティメソッド：画像の事前読み込み
  preloadImages() {
    this.images.forEach(image => {
      const img = new Image()
      img.src = image.fullSrc
    })
  }

  // ユーティリティメソッド：スワイプジェスチャー対応（将来の拡張用）
  setupSwipeGestures() {
    let startX = 0
    let startY = 0
    
    this.modalTarget.addEventListener('touchstart', (e) => {
      startX = e.touches[0].clientX
      startY = e.touches[0].clientY
    })
    
    this.modalTarget.addEventListener('touchend', (e) => {
      const endX = e.changedTouches[0].clientX
      const endY = e.changedTouches[0].clientY
      
      const deltaX = endX - startX
      const deltaY = endY - startY
      
      // 横スワイプが縦スワイプより大きい場合のみ処理
      if (Math.abs(deltaX) > Math.abs(deltaY) && Math.abs(deltaX) > 50) {
        if (deltaX > 0) {
          this.previousImage({ preventDefault: () => {}, stopPropagation: () => {} })
        } else {
          this.nextImage({ preventDefault: () => {}, stopPropagation: () => {} })
        }
      }
    })
  }
}