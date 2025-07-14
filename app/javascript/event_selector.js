// イベント選択機能 - ベテランバックエンドエンジニアによるUX最適化実装
console.log('event_selector.js: スクリプト読み込み完了');

// イベント選択関数
function setEventSelection(eventId) {
  const eventSelect = document.getElementById('gift_record_event_id');
  
  if (!eventSelect) {
    console.warn('event_selector.js: イベント選択フィールドが見つかりません');
    return;
  }

  // イベントを選択
  eventSelect.value = eventId;
  
  // 変更イベントを発火（バリデーションや他のイベントリスナー向け）
  eventSelect.dispatchEvent(new Event('change', { bubbles: true }));
  
  // ユーザーフィードバック（視覚的な確認）
  eventSelect.focus();
  eventSelect.classList.add('is-valid');
  
  // 一時的なハイライト効果
  setTimeout(() => {
    eventSelect.classList.remove('is-valid');
  }, 1500);

  console.log(`event_selector.js: イベントを選択しました - ID: ${eventId}`);
}

// イベント選択の初期化とエンハンスメント
function initializeEventSelector() {
  console.log('event_selector.js: イベントセレクター初期化開始');
  
  const eventSelect = document.getElementById('gift_record_event_id');
  
  if (!eventSelect) {
    console.log('event_selector.js: イベント選択フィールドが見つかりません - スキップ');
    return;
  }

  // リアルタイムバリデーション（UX最適化版）
  eventSelect.addEventListener('change', function() {
    console.log('event_selector.js: イベント選択変更:', this.value);
    
    // バリデーションフィードバック
    this.classList.remove('is-valid', 'is-invalid');
    
    if (this.value && this.value !== '') {
      this.classList.add('is-valid');
      
      // 選択されたイベント名をログ出力
      const selectedOption = this.options[this.selectedIndex];
      console.log('event_selector.js: 選択されたイベント:', selectedOption.text);
    }
    // 未選択の場合は中立状態を維持（エラー表示はフォーム送信時のみ）
  });

  // フォーカス時のヘルプ表示
  eventSelect.addEventListener('focus', function() {
    const helpText = document.getElementById('event_help');
    if (helpText) {
      helpText.style.fontWeight = 'bold';
      helpText.style.color = '#0d6efd';
    }
  });

  // フォーカス離脱時のヘルプ戻し
  eventSelect.addEventListener('blur', function() {
    const helpText = document.getElementById('event_help');
    if (helpText) {
      helpText.style.fontWeight = 'normal';
      helpText.style.color = '#6c757d';
    }
  });

  // 初期状態では中立的な状態に設定（バリデーションエラーを表示しない）
  eventSelect.classList.remove('is-invalid', 'is-valid');

  // ツールチップの初期化
  if (typeof bootstrap !== 'undefined' && bootstrap.Tooltip) {
    const tooltipElements = document.querySelectorAll('[data-bs-toggle="tooltip"]');
    tooltipElements.forEach(element => {
      new bootstrap.Tooltip(element);
    });
  }

  // フォーム送信時のバリデーション
  const form = eventSelect.closest('form');
  if (form) {
    form.addEventListener('submit', function(event) {
      if (!eventSelect.value || eventSelect.value === '') {
        event.preventDefault();
        eventSelect.classList.add('is-invalid');
        eventSelect.focus();
        console.log('event_selector.js: フォーム送信阻止 - イベントが未選択');
        
        // エラーメッセージを表示（カスタムバリデーション）
        eventSelect.setCustomValidity('イベントを選択してください');
        eventSelect.reportValidity();
      } else {
        eventSelect.setCustomValidity('');
      }
    });
  }

  console.log('event_selector.js: イベントセレクター初期化完了');
}

// キーボードショートカット（アクセシビリティ向上）
function setupEventSelectorKeyboardShortcuts() {
  document.addEventListener('keydown', function(event) {
    // Ctrl + E でイベント選択フィールドにフォーカス
    if (event.ctrlKey && event.key === 'e') {
      event.preventDefault();
      const eventSelect = document.getElementById('gift_record_event_id');
      if (eventSelect) {
        eventSelect.focus();
        console.log('event_selector.js: キーボードショートカットでイベント選択フィールドにフォーカス');
      }
    }
  });
}

// 初期化関数
function initializeAllEventFeatures() {
  initializeEventSelector();
  setupEventSelectorKeyboardShortcuts();
}

// 複数のタイミングで初期化
document.addEventListener('DOMContentLoaded', initializeAllEventFeatures);
document.addEventListener('turbo:load', initializeAllEventFeatures);
document.addEventListener('turbo:render', initializeAllEventFeatures);

// 遅延初期化
setTimeout(initializeAllEventFeatures, 100);

// グローバルデバッグ関数
window.debugEventSelector = function() {
  console.log('=== イベントセレクター デバッグ情報 ===');
  const eventSelect = document.getElementById('gift_record_event_id');
  console.log('選択フィールド存在:', !!eventSelect);
  console.log('現在の値:', eventSelect?.value);
  console.log('選択肢数:', eventSelect?.options.length);
  if (eventSelect) {
    console.log('全選択肢:', Array.from(eventSelect.options).map(opt => ({ value: opt.value, text: opt.text })));
  }
};

// グローバル関数として公開（HTMLから呼び出し用）
window.setEventSelection = setEventSelection;