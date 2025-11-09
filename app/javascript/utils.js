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

// シンプルなデバウンス
export function debounce(fn, delay = 300) {
  let timerId;
  const debounced = (...args) => {
    if (timerId) clearTimeout(timerId);
    timerId = setTimeout(() => fn(...args), delay);
  };
  debounced.cancel = () => timerId && clearTimeout(timerId);
  return debounced;
}

// グローバルに公開
window.getCSRFToken = getCSRFToken;
window.escapeHtml = escapeHtml;
window.getAPIHeaders = getAPIHeaders;
window.turboInit = turboInit;

// トースト通知（最小限の共通関数）
export function showToast(message, type = 'info') {
  const existingToast = document.querySelector('.favorite-toast');
  if (existingToast) existingToast.remove();

  const toast = document.createElement('div');
  toast.className = 'favorite-toast fixed right-4 top-16 sm:top-20 md:top-24 z-50 px-4 py-2 rounded-lg shadow-lg max-w-xs transform transition-all duration-300 translate-x-full opacity-0';

  if (type === 'success') {
    toast.classList.add('bg-green-500', 'text-white');
    toast.innerHTML = `<i class="fas fa-check mr-2"></i>${message}`;
  } else if (type === 'error') {
    toast.classList.add('bg-red-500', 'text-white');
    toast.innerHTML = `<i class="fas fa-exclamation-triangle mr-2"></i>${message}`;
  } else {
    toast.classList.add('bg-blue-500', 'text-white');
    toast.innerHTML = `<i class="fas fa-info-circle mr-2"></i>${message}`;
  }

  document.body.appendChild(toast);
  setTimeout(() => { toast.classList.remove('translate-x-full', 'opacity-0'); }, 100);
  setTimeout(() => {
    toast.classList.add('translate-x-full', 'opacity-0');
    setTimeout(() => { toast.remove(); }, 300);
  }, 3000);
}
