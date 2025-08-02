// ハンバーガーメニューの制御 - イベントデリゲーションパターン

let isHamburgerInitialized = false;

// イベントデリゲーションパターンで堅牢な実装
function initializeHamburgerMenuDelegation() {
  console.log('🍔 [HAMBURGER] 初期化開始', {
    timestamp: Date.now(),
    isAlreadyInitialized: isHamburgerInitialized,
    readyState: document.readyState
  });
  
  if (isHamburgerInitialized) {
    console.log('🍔 [HAMBURGER] 既に初期化済み、スキップ');
    return;
  }

  // ドキュメント全体でクリックイベントを捕捉
  document.addEventListener('click', function(event) {
    // 【CTOによる処理済みイベント検出】
    if (event.type === 'click-consumed') {
      console.log('🍔 [HAMBURGER] 処理済みイベントを検出、完全スキップ');
      return;
    }
    
    console.log('🍔 [HAMBURGER] クリックイベント捕捉', {
      target: event.target,
      targetId: event.target.id || '',
      targetClasses: event.target.className || '',
      eventPhase: event.eventPhase,
      eventType: event.type,
      timestamp: Date.now()
    });

    // 【削除モーダル専用システム対応】削除ボタン検出・除外
    const deleteButtonByData = event.target.closest('[data-delete-modal="true"]');
    const deleteButtonByClass = event.target.closest('.delete-modal-trigger');
    const deleteButtonByAria = event.target.closest('button[aria-label*="削除"]');
    
    const isDeleteButton = deleteButtonByData || deleteButtonByClass || deleteButtonByAria;
    
    console.log('🍔 [HAMBURGER] 削除ボタンチェック', {
      byData: !!deleteButtonByData,
      byClass: !!deleteButtonByClass,
      byAria: !!deleteButtonByAria,
      isDeleteButton: !!isDeleteButton,
      targetClasses: event.target.className
    });
    
    if (isDeleteButton) {
      console.log('🍔 [HAMBURGER] 削除ボタン検出、ハンバーガーメニュー処理をスキップ');
      return;
    }

    // ハンバーガーメニューボタンのクリック判定 
    const menuToggleButton = event.target.closest('#menu-toggle');
    if (menuToggleButton) {
      console.log('🍔 hamburger_menu.js: メニューボタンクリック検出');
      event.preventDefault();
      event.stopPropagation();
      
      const menu = document.getElementById('menu');
      if (menu) {
        menu.classList.toggle('hidden');
      }
      return;
    }

    // メニュー外クリックの判定
    const menu = document.getElementById('menu');
    const menuToggle = document.getElementById('menu-toggle');
    
    if (menu && menuToggle && !menu.classList.contains('hidden')) {
      // メニューが開いている状態で、メニューまたはボタン以外をクリックした場合
      if (!menu.contains(event.target) && !menuToggle.contains(event.target)) {
        console.log('🍔 hamburger_menu.js: メニュー外クリック、メニューを閉じる');
        menu.classList.add('hidden');
      }
    }
  });

  isHamburgerInitialized = true;
  return true;
}

// Turbo対応初期化（modal_manager.jsの後に実行するため少し遅延）
if (window.turboInit) {
  window.turboInit(() => {
    // modal_manager.jsの初期化完了を待つため、わずかに遅延
    setTimeout(() => {
      console.log('🍔 [HAMBURGER] 遅延初期化実行');
      initializeHamburgerMenuDelegation();
    }, 10); // 10ms遅延
    return true;
  });
} else {
  // フォールバック
  document.addEventListener('DOMContentLoaded', () => {
    setTimeout(initializeHamburgerMenuDelegation, 10);
  });
  document.addEventListener('turbo:load', () => {
    setTimeout(initializeHamburgerMenuDelegation, 10);
  });
}
