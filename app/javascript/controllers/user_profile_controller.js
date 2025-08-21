import { Controller } from "@hotwired/stimulus"

// ユーザープロフィール表示ページのUIエフェクトを管理するStimulusコントローラー
// data-controller="user-profile" に接続
export default class extends Controller {
  static targets = [
    "card", // ホバー効果を適用するカード
    "monthlyRow" // 月別統計行
  ]

  connect() {
    // 特に初期化処理は不要
  }

  // カードのマウスエンター時の処理
  cardMouseEnter(event) {
    const card = event.currentTarget
    
    // ホバーエフェクト: 上に移動 + 影を強化
    card.style.transform = 'translateY(-2px)'
    card.style.boxShadow = '0 10px 25px rgba(0, 0, 0, 0.1)'
    card.style.transition = 'all 0.2s ease'
  }

  // カードのマウスリーブ時の処理
  cardMouseLeave(event) {
    const card = event.currentTarget
    
    // 元の状態に戻す
    card.style.transform = 'translateY(0)'
    card.style.boxShadow = '0 4px 6px rgba(0, 0, 0, 0.1)'
    card.style.transition = 'all 0.2s ease'
  }

  // 月別統計行のマウスエンター時の処理
  monthlyRowMouseEnter(event) {
    const row = event.currentTarget
    
    // ホバーエフェクト: 背景色変更 + 右に移動
    row.style.backgroundColor = '#f9fafb'
    row.style.transform = 'translateX(4px)'
    row.style.transition = 'all 0.2s ease'
  }

  // 月別統計行のマウスリーブ時の処理
  monthlyRowMouseLeave(event) {
    const row = event.currentTarget
    
    // 元の状態に戻す
    row.style.backgroundColor = ''
    row.style.transform = 'translateX(0)'
    row.style.transition = 'all 0.2s ease'
  }
}