// ハンバーガーメニューの制御 - イベントデリゲーションパターン
console.log('hamburger_menu.js: スクリプト読み込み完了');

let isHamburgerInitialized = false;

// イベントデリゲーションパターンで堅牢な実装
function initializeHamburgerMenuDelegation() {
  if (isHamburgerInitialized) {
    console.log('hamburger_menu.js: 既に初期化済み');
    return;
  }

  console.log('hamburger_menu.js: イベントデリゲーション初期化開始');

  // ドキュメント全体でクリックイベントを捕捉
  document.addEventListener('click', function(event) {
    console.log('hamburger_menu.js: クリックイベント捕捉', {
      target: event.target,
      targetId: event.target.id,
      targetClasses: event.target.className
    });

    // ハンバーガーメニューボタンのクリック判定
    const menuToggleButton = event.target.closest('#menu-toggle');
    if (menuToggleButton) {
      console.log('hamburger_menu.js: ハンバーガーメニューボタンクリック検出');
      event.preventDefault();
      event.stopPropagation();
      
      const menu = document.getElementById('menu');
      if (menu) {
        const isHidden = menu.classList.contains('hidden');
        console.log('hamburger_menu.js: メニュー状態変更', { 
          wasHidden: isHidden, 
          willBeHidden: !isHidden 
        });
        menu.classList.toggle('hidden');
      } else {
        console.error('hamburger_menu.js: メニュー要素が見つかりません');
      }
      return;
    }

    // メニュー外クリックの判定
    const menu = document.getElementById('menu');
    const menuToggle = document.getElementById('menu-toggle');
    
    if (menu && menuToggle && !menu.classList.contains('hidden')) {
      // メニューが開いている状態で、メニューまたはボタン以外をクリックした場合
      if (!menu.contains(event.target) && !menuToggle.contains(event.target)) {
        console.log('hamburger_menu.js: メニュー外クリック - メニューを閉じる');
        menu.classList.add('hidden');
      }
    }
  });

  isHamburgerInitialized = true;
  console.log('hamburger_menu.js: イベントデリゲーション初期化完了');
}

// DOM状態チェック関数
function checkDOMState() {
  const menuToggle = document.getElementById('menu-toggle');
  const menu = document.getElementById('menu');
  
  console.log('hamburger_menu.js: DOM状態チェック', {
    menuToggleExists: !!menuToggle,
    menuExists: !!menu,
    menuToggleVisible: menuToggle ? window.getComputedStyle(menuToggle).display !== 'none' : false,
    menuHidden: menu ? menu.classList.contains('hidden') : false
  });
  
  return { menuToggle, menu };
}

// 複数のタイミングで初期化を試行
function safeInitialize() {
  console.log('hamburger_menu.js: 安全な初期化実行');
  checkDOMState();
  initializeHamburgerMenuDelegation();
}

// DOMContentLoaded（最優先）
document.addEventListener('DOMContentLoaded', safeInitialize);

// Turboイベント
document.addEventListener('turbo:load', safeInitialize);
document.addEventListener('turbo:render', safeInitialize);

// 遅延初期化（DOM構築完了後）
setTimeout(safeInitialize, 100);

// 緊急措置：1秒後に強制初期化
setTimeout(() => {
  if (!isHamburgerInitialized) {
    console.warn('hamburger_menu.js: 緊急措置による強制初期化');
    safeInitialize();
  }
}, 1000);
