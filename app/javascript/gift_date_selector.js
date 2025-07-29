// ギフト日付選択機能
// 日付フォーマット関数
function formatDateForInput(date) {
  return date.toISOString().split('T')[0];
}

// クイック日付設定関数
function setGiftDate(dateType) {
  const giftDateInput = document.getElementById('gift_record_gift_at');
  
  if (!giftDateInput) {
    console.warn('gift_date_selector.js: ギフト日付入力フィールドが見つかりません');
    return;
  }

  let targetDate = new Date();
  
  switch(dateType) {
    case 'today':
      // 今日の日付
      targetDate = new Date();
      break;
    case 'yesterday':
      // 昨日の日付
      targetDate = new Date();
      targetDate.setDate(targetDate.getDate() - 1);
      break;
    case 'week_ago':
      // 1週間前の日付
      targetDate = new Date();
      targetDate.setDate(targetDate.getDate() - 7);
      break;
    default:
      console.warn('gift_date_selector.js: 不明な日付タイプ:', dateType);
      return;
  }

  // 日付フィールドに値を設定
  const formattedDate = formatDateForInput(targetDate);
  giftDateInput.value = formattedDate;
  
  // 変更イベントを発火（バリデーションや他のイベントリスナー向け）
  giftDateInput.dispatchEvent(new Event('change', { bubbles: true }));
  
  // ユーザーフィードバック（視覚的な確認）
  giftDateInput.focus();
  giftDateInput.classList.add('is-valid');
  
  // 一時的なハイライト効果
  setTimeout(() => {
    giftDateInput.classList.remove('is-valid');
  }, 1500);

}

// 日付入力の初期化とエンハンスメント
function initializeGiftDateSelector() {
  console.log('gift_date_selector.js: 日付セレクター初期化開始');
  
  const giftDateInput = document.getElementById('gift_record_gift_at');
  
  if (!giftDateInput) {
    console.log('gift_date_selector.js: ギフト日付入力フィールドが見つかりません - スキップ');
    return;
  }

  // デフォルト値の設定（空の場合のみ）
  if (!giftDateInput.value) {
    const defaultDate = giftDateInput.dataset.defaultDate;
    if (defaultDate) {
      giftDateInput.value = defaultDate;
      console.log('gift_date_selector.js: デフォルト日付を設定:', defaultDate);
    }
  }

  // リアルタイムバリデーション
  giftDateInput.addEventListener('change', function() {
    const selectedDate = new Date(this.value);
    const currentDate = new Date();
    const minDate = new Date();
    minDate.setFullYear(currentDate.getFullYear() - 100);
    const maxDate = new Date();
    maxDate.setFullYear(currentDate.getFullYear() + 1);

    // バリデーションフィードバック
    this.classList.remove('is-valid', 'is-invalid');
    
    if (this.value && selectedDate >= minDate && selectedDate <= maxDate) {
      this.classList.add('is-valid');
    } else if (this.value) {
      this.classList.add('is-invalid');
    }
  });

  // ツールチップの初期化
  if (typeof bootstrap !== 'undefined' && bootstrap.Tooltip) {
    const tooltipElements = document.querySelectorAll('[data-bs-toggle="tooltip"]');
    tooltipElements.forEach(element => {
      new bootstrap.Tooltip(element);
    });
  }

  console.log('gift_date_selector.js: 日付セレクター初期化完了');
}

// 初期化関数
function initializeAllGiftDateFeatures() {
  initializeGiftDateSelector();
}

// 複数のタイミングで初期化
document.addEventListener('DOMContentLoaded', initializeAllGiftDateFeatures);
document.addEventListener('turbo:load', initializeAllGiftDateFeatures);
document.addEventListener('turbo:render', initializeAllGiftDateFeatures);

// 遅延初期化
setTimeout(initializeAllGiftDateFeatures, 100);

// グローバルデバッグ関数
window.debugGiftDateSelector = function() {
  console.log('=== ギフト日付セレクター デバッグ情報 ===');
  const giftDateInput = document.getElementById('gift_record_gift_at');
  console.log('入力フィールド存在:', !!giftDateInput);
  console.log('現在の値:', giftDateInput?.value);
  console.log('最小日付:', giftDateInput?.min);
  console.log('最大日付:', giftDateInput?.max);
};

// グローバル関数として公開（HTMLから呼び出し用）
window.setGiftDate = setGiftDate;
