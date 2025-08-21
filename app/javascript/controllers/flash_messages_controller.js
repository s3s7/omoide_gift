import { Controller } from "@hotwired/stimulus"

// フラッシュメッセージの表示・自動消去・手動消去を管理するStimulusコントローラー
// data-controller="flash-messages" に接続
export default class extends Controller {
  static targets = ["message"]
  
  static values = {
    autoHideDuration: { type: Number, default: 3000 }, // 自動消去までの時間（ミリ秒）
    stagingDelay: { type: Number, default: 200 } // 段階的表示の遅延時間（ミリ秒）
  }

  connect() {
    // フラッシュメッセージの初期化処理を実行
    this.initializeMessages()
  }

  disconnect() {
    // コントローラー切断時にタイマーをクリーンアップ
    this.clearAllTimers()
  }

  // フラッシュメッセージの初期化（段階的表示と自動消去の設定）
  initializeMessages() {
    // タイマーIDを保存する配列を初期化
    this.timers = []
    
    this.messageTargets.forEach((message, index) => {
      // 段階的表示の実装
      const showTimer = setTimeout(() => {
        if (message && message.isConnected) {
          message.style.opacity = '1'
          message.style.transform = 'translateX(0)'
        }
      }, index * this.stagingDelayValue)
      
      this.timers.push(showTimer)
      
      // 自動消去の実装（表示遅延時間も考慮）
      const hideTimer = setTimeout(() => {
        if (message && message.isConnected) {
          this.dismissMessage(message)
        }
      }, this.autoHideDurationValue + (index * this.stagingDelayValue))
      
      this.timers.push(hideTimer)
    })
  }

  // 手動でフラッシュメッセージを閉じる処理（閉じるボタンクリック時）
  dismiss(event) {
    const button = event.currentTarget
    const messageElement = button.closest('.flash-message')
    
    if (messageElement) {
      this.dismissMessage(messageElement)
    }
  }

  // フラッシュメッセージを消去する共通処理
  dismissMessage(messageElement) {
    if (!messageElement || !messageElement.classList.contains('flash-message')) {
      return
    }

    // フェードアウトアニメーションを開始
    messageElement.classList.add('fade-out')
    
    // アニメーション完了後にDOMから削除
    const removeTimer = setTimeout(() => {
      if (messageElement && messageElement.isConnected) {
        messageElement.remove()
      }
    }, 300) // CSSのアニメーション時間と同期
    
    this.timers.push(removeTimer)
  }

  // すべてのタイマーをクリアする処理（メモリリーク防止）
  clearAllTimers() {
    if (this.timers) {
      this.timers.forEach(timer => clearTimeout(timer))
      this.timers = []
    }
  }

  // Turboナビゲーション開始時にメッセージをクリア
  beforeVisit() {
    this.clearAllTimers()
    this.element.innerHTML = ''
  }
}