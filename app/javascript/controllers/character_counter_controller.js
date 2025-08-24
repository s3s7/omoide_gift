import { Controller } from "@hotwired/stimulus"

// 文字数カウンター機能を提供するStimulusコントローラー
// data-controller="character-counter" に接続
export default class extends Controller {
  static targets = ["input", "counter"]
  
  static values = {
    maxLength: { type: Number, default: 100 },
    warningThreshold: { type: Number, default: 80 },
    dangerThreshold: { type: Number, default: 90 },
    enableColorChange: { type: Boolean, default: true }
  }

  connect() {
    // 初期値の設定
    this.updateCounter()
  }

  // 入力時の処理
  inputChanged() {
    this.updateCounter()
  }

  // 文字数カウンターの更新
  updateCounter() {
    if (!this.hasInputTarget || !this.hasCounterTarget) {
      return
    }

    const length = this.inputTarget.value.length
    this.counterTarget.textContent = length

    // 文字数に応じてスタイルを変更
    this.updateCounterStyle(length)
  }

  // カウンタのスタイルを更新
  updateCounterStyle(length) {
    // 色変更が無効な場合は何もしない
    if (!this.enableColorChangeValue) {
      return
    }

    // 既存のクラスを削除
    this.counterTarget.className = this.counterTarget.className
      .replace(/text-red-600|font-bold|text-yellow-600|font-medium|text-gray-600/g, '')
      .trim()

    if (length >= this.dangerThresholdValue) {
      // 90文字以上：赤色、太字
      this.counterTarget.classList.add('text-red-600', 'font-bold')
    } else if (length >= this.warningThresholdValue) {
      // 80文字以上：黄色、中太字
      this.counterTarget.classList.add('text-yellow-600', 'font-medium')
    } else {
      // 通常：グレー
      this.counterTarget.classList.add('text-gray-600')
    }
  }
}