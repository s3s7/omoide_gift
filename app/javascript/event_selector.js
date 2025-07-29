// イベント選択機能
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
}

// イベント選択の初期化とエンハンスメント
function initializeEventSelector() {
  const eventSelect = document.getElementById('gift_record_event_id');
  
  if (!eventSelect) {
    return;
  }

  // リアルタイムバリデーション（UX最適化版）
  eventSelect.addEventListener('change', function() {
    
    // バリデーションフィードバック
    this.classList.remove('is-valid', 'is-invalid');
    
    if (this.value && this.value !== '') {
      this.classList.add('is-valid');
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
        
        // エラーメッセージを表示（カスタムバリデーション）
        eventSelect.setCustomValidity('イベントを選択してください');
        eventSelect.reportValidity();
      } else {
        eventSelect.setCustomValidity('');
      }
    });
  }


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

// グローバル関数として公開（HTMLから呼び出し用）
window.setEventSelection = setEventSelection;
