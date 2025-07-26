// 共通ユーティリティ関数

// CSRFトークンを取得
export function getCSRFToken() {
  const token = document.querySelector('meta[name="csrf-token"]');
  return token ? token.getAttribute('content') : '';
}


// グローバルに公開
window.getCSRFToken = getCSRFToken;

