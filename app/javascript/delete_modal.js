// 削除モーダル専用システム - シンプル実装

console.log('🗑️ [DELETE_MODAL] 専用システム読み込み開始');

// 削除モーダル表示関数
function showDeleteModal(itemName, deleteUrl, csrfToken) {
  console.log('🗑️ [DELETE_MODAL] showDeleteModal呼び出し:', {
    itemName,
    deleteUrl,
    csrfToken: !!csrfToken,
    timestamp: Date.now()
  });

  // DOM要素を取得
  const modal = document.getElementById('delete-confirmation-modal');
  const itemNameSpan = document.getElementById('delete-item-name');
  const confirmBtn = document.getElementById('confirm-delete-btn');
  const cancelBtn = document.getElementById('cancel-delete-btn');

  console.log('🗑️ [DELETE_MODAL] DOM要素チェック:', {
    modal: !!modal,
    itemNameSpan: !!itemNameSpan,
    confirmBtn: !!confirmBtn,
    cancelBtn: !!cancelBtn
  });

  if (!modal || !itemNameSpan || !confirmBtn || !cancelBtn) {
    console.error('🗑️ [DELETE_MODAL] 必要なDOM要素が不足しています');
    // フォールバック: ブラウザのconfirm
    if (confirm(`${itemName || 'このアイテム'}を削除しますか？`)) {
      if (deleteUrl && csrfToken) {
        submitDeleteForm(deleteUrl, csrfToken);
      }
    }
    return;
  }

  // アイテム名を設定
  itemNameSpan.textContent = itemName || 'このアイテム';

  // 確認ボタンのイベントハンドラーを設定
  const handleConfirm = () => {
    console.log('🗑️ [DELETE_MODAL] 削除確認ボタンクリック');
    hideDeleteModal();
    if (deleteUrl && csrfToken) {
      submitDeleteForm(deleteUrl, csrfToken);
    }
  };

  // キャンセルボタンのイベントハンドラーを設定
  const handleCancel = () => {
    console.log('🗑️ [DELETE_MODAL] キャンセルボタンクリック');
    hideDeleteModal();
  };

  // 既存のイベントリスナーを削除して新しく設定
  const newConfirmBtn = confirmBtn.cloneNode(true);
  const newCancelBtn = cancelBtn.cloneNode(true);
  
  confirmBtn.parentNode.replaceChild(newConfirmBtn, confirmBtn);
  cancelBtn.parentNode.replaceChild(newCancelBtn, cancelBtn);

  newConfirmBtn.addEventListener('click', handleConfirm);
  newCancelBtn.addEventListener('click', handleCancel);

  console.log('🗑️ [DELETE_MODAL] イベントリスナー設定完了');

  // モーダルを表示
  showModal();
}

// モーダル表示
function showModal() {
  const modal = document.getElementById('delete-confirmation-modal');
  if (!modal) return;

  console.log('🗑️ [DELETE_MODAL] モーダル表示開始');

  // 確実に表示
  modal.classList.remove('hidden');
  modal.style.display = 'flex';
  modal.style.visibility = 'visible';
  modal.style.zIndex = '9999';
  
  // 背景スクロール停止
  document.body.style.overflow = 'hidden';

  // 背景クリックでモーダルを閉じる
  modal.addEventListener('click', (e) => {
    if (e.target === modal) {
      hideDeleteModal();
    }
  });

  // ESCキーでモーダルを閉じる
  const handleEscape = (e) => {
    if (e.key === 'Escape') {
      hideDeleteModal();
      document.removeEventListener('keydown', handleEscape);
    }
  };
  document.addEventListener('keydown', handleEscape);

  console.log('🗑️ [DELETE_MODAL] モーダル表示完了');
}

// モーダル非表示
function hideDeleteModal() {
  const modal = document.getElementById('delete-confirmation-modal');
  if (!modal) return;

  console.log('🗑️ [DELETE_MODAL] モーダル非表示開始');

  modal.classList.add('hidden');
  modal.style.display = 'none';
  document.body.style.overflow = 'auto';

  console.log('🗑️ [DELETE_MODAL] モーダル非表示完了');
}

// 削除フォーム送信
function submitDeleteForm(deleteUrl, csrfToken) {
  console.log('🗑️ [DELETE_MODAL] 削除フォーム送信:', { deleteUrl, csrfToken: !!csrfToken });

  const form = document.createElement('form');
  form.method = 'POST';
  form.action = deleteUrl;

  // CSRF トークン
  const csrfInput = document.createElement('input');
  csrfInput.type = 'hidden';
  csrfInput.name = 'authenticity_token';
  csrfInput.value = csrfToken;
  form.appendChild(csrfInput);

  // DELETE メソッド
  const methodInput = document.createElement('input');
  methodInput.type = 'hidden';
  methodInput.name = '_method';
  methodInput.value = 'delete';
  form.appendChild(methodInput);

  // フォームをDOMに追加して送信
  document.body.appendChild(form);
  form.submit();

  console.log('🗑️ [DELETE_MODAL] 削除フォーム送信完了');
}

// 削除ボタンのイベントデリゲーション（最優先度）
function setupDeleteButtonEvents() {
  console.log('🗑️ [DELETE_MODAL] イベントデリゲーション設定開始');

  // capture phaseで最優先実行
  document.addEventListener('click', function(event) {
    console.log('🗑️ [DELETE_MODAL] クリックイベント:', {
      target: event.target.tagName,
      classes: event.target.className,
      hasDeleteModal: event.target.hasAttribute('data-delete-modal'),
      timestamp: Date.now()
    });

    // 削除ボタンを検出（複数パターン）
    let deleteButton = null;
    
    // 1. data-delete-modal属性
    deleteButton = event.target.closest('[data-delete-modal="true"]');
    
    // 2. delete-modal-triggerクラス
    if (!deleteButton) {
      deleteButton = event.target.closest('.delete-modal-trigger');
    }
    
    // 3. 削除ボタンのaria-label
    if (!deleteButton) {
      deleteButton = event.target.closest('button[aria-label*="削除"]');
    }

    if (deleteButton) {
      console.log('🗑️ [DELETE_MODAL] 削除ボタン検出:', deleteButton);

      // イベント停止
      event.preventDefault();
      event.stopPropagation();
      event.stopImmediatePropagation();

      // data属性から情報取得
      const itemName = deleteButton.dataset.itemName || deleteButton.getAttribute('title') || 'このアイテム';
      const deleteUrl = deleteButton.dataset.deleteUrl;
      const csrfToken = deleteButton.dataset.csrfToken;

      console.log('🗑️ [DELETE_MODAL] 削除情報:', { itemName, deleteUrl, csrfToken: !!csrfToken });

      // 削除モーダル表示
      showDeleteModal(itemName, deleteUrl, csrfToken);

      return false;
    }
  }, true); // capture: true で最優先実行

  console.log('🗑️ [DELETE_MODAL] イベントデリゲーション設定完了');
}

// 初期化
function initializeDeleteModal() {
  console.log('🗑️ [DELETE_MODAL] 初期化開始:', {
    readyState: document.readyState,
    deleteModalElements: document.querySelectorAll('[data-delete-modal="true"]').length,
    modalExists: !!document.getElementById('delete-confirmation-modal')
  });

  setupDeleteButtonEvents();

  console.log('🗑️ [DELETE_MODAL] 初期化完了');
  return true;
}

// グローバル関数として公開
window.showDeleteModal = showDeleteModal;
window.hideDeleteModal = hideDeleteModal;

// 即座にイベントリスナーを設定（他のスクリプトより先に）
setupDeleteButtonEvents();

// DOM準備後の初期化
if (document.readyState === 'loading') {
  document.addEventListener('DOMContentLoaded', () => {
    console.log('🗑️ [DELETE_MODAL] DOMContentLoaded初期化');
    // イベントリスナーは既に設定済み
  });
} else {
  console.log('🗑️ [DELETE_MODAL] DOM既に準備完了');
}

// Turbo対応
document.addEventListener('turbo:load', () => {
  console.log('🗑️ [DELETE_MODAL] turbo:load初期化');
  // イベントリスナーは既に設定済み
});

console.log('🗑️ [DELETE_MODAL] 専用システム読み込み完了:', {
  showDeleteModal: !!window.showDeleteModal,
  hideDeleteModal: !!window.hideDeleteModal
});