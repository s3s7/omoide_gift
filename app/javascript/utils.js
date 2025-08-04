// 共通ユーティリティ関数

// CSRFトークンを取得
export function getCSRFToken() {
  const token = document.querySelector('meta[name="csrf-token"]');
  return token ? token.getAttribute('content') : '';
}

// HTML エスケープ（重複削除）
export function escapeHtml(text) {
  const div = document.createElement('div');
  div.textContent = text;
  return div.innerHTML;
}

// API リクエスト用の共通ヘッダー生成
export function getAPIHeaders() {
  const csrfToken = getCSRFToken();
  const headers = {
    'Accept': 'application/json',
    'Content-Type': 'application/json',
    'X-Requested-With': 'XMLHttpRequest'
  };

  if (csrfToken) {
    headers['X-CSRF-Token'] = csrfToken;
  }

  return headers;
}

// Turbo対応の共通初期化パターン
export function turboInit(initFunction) {
  let initialized = false;

  const safeInit = () => {
    if (initialized) return;
    try {
      if (initFunction()) {
        initialized = true;
      }
    } catch (error) {
      console.error('初期化エラー:', error);
    }
  };

  document.addEventListener('DOMContentLoaded', safeInit);
  document.addEventListener('turbo:load', safeInit);
  document.addEventListener('turbo:render', safeInit);
  setTimeout(safeInit, 100);
}

// グローバルに公開
window.getCSRFToken = getCSRFToken;
window.escapeHtml = escapeHtml;
window.getAPIHeaders = getAPIHeaders;
window.turboInit = turboInit;
