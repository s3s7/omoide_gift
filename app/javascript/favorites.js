// お気に入り機能 - Twitterライクなハートボタン

// ページ読み込み時に初期化
document.addEventListener('DOMContentLoaded', function() {
  initializeFavorites();
});

// お気に入り機能の初期化
function initializeFavorites() {
  // 既存のイベントリスナーを削除（重複回避）
  document.removeEventListener('click', handleFavoriteClick);
  
  // クリックイベントを委譲で設定
  document.addEventListener('click', handleFavoriteClick);
}

// お気に入りクリックハンドラ
function handleFavoriteClick(event) {
  const button = event.target.closest('.favorite-button');
  if (!button) return;
  
  event.stopPropagation();
  event.preventDefault();
  
  const giftRecordId = button.closest('.favorite-button-container').dataset.giftRecordId;
  if (!giftRecordId) return;
  
  toggleFavorite(giftRecordId);
}

// お気に入りToggle機能
async function toggleFavorite(giftRecordId) {
  const container = document.querySelector(`[data-gift-record-id="${giftRecordId}"]`);
  const button = container?.querySelector('.favorite-button');
  
  if (!container || !button) {
    console.error('Favorite button not found for gift record:', giftRecordId);
    return;
  }

  // ローディング状態を設定
  setLoadingState(button, true);

  try {
    const response = await fetch(`/gift_records/${giftRecordId}/toggle_favorite`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'X-CSRF-Token': window.getCSRFToken(),
        'Accept': 'application/json'
      },
      credentials: 'same-origin'
    });

    const data = await response.json();

    if (data.success) {
      updateFavoriteButton(container, data.favorited, data.favorites_count);
      showFavoriteMessage(data.action, data.favorited);
    } else {
      showFavoriteError(data.error || 'エラーが発生しました');
    }
  } catch (error) {
    console.error('Favorite toggle error:', error);
    showFavoriteError('ネットワークエラーが発生しました');
  } finally {
    setLoadingState(button, false);
  }
}

// ボタンの表示を更新
function updateFavoriteButton(container, favorited, favoritesCount) {
  const button = container.querySelector('.favorite-button');
  const heart = button.querySelector('.favorite-heart');
  const countElement = button.querySelector('.favorite-count');

  // ボタンの状態を更新
  button.dataset.favorited = favorited.toString();
  button.classList.toggle('favorited', favorited);
  
  // ハートアイコンを更新
  heart.className = `favorite-heart ${favorited ? 'fas' : 'far'} fa-heart`;
  
  // アニメーション効果
  if (favorited) {
    heart.style.animation = 'none';
    setTimeout(() => {
      heart.style.animation = 'heartBeat 0.3s ease';
    }, 10);
  }
  
  // カウント表示を更新
  if (favoritesCount > 0) {
    if (countElement) {
      countElement.textContent = favoritesCount;
    } else {
      // カウント要素を新規作成
      const newCountElement = document.createElement('span');
      newCountElement.className = 'favorite-count';
      newCountElement.textContent = favoritesCount;
      button.appendChild(newCountElement);
    }
  } else {
    // カウントが0の場合は要素を削除
    if (countElement) {
      countElement.remove();
    }
  }

  // ツールチップを更新
  const newTitle = favorited ? 'お気に入りから削除' : 'お気に入りに追加';
  button.title = newTitle;
  button.setAttribute('aria-label', newTitle);
}

// ローディング状態の設定
function setLoadingState(button, isLoading) {
  button.classList.toggle('loading', isLoading);
  button.disabled = isLoading;
}

// 成功メッセージの表示
function showFavoriteMessage(action, favorited) {
  const message = action === 'added' ? 'お気に入りに追加しました' : 'お気に入りから削除しました';
  showToast(message, 'success');
}

// エラーメッセージの表示  
function showFavoriteError(error) {
  showToast(error, 'error');
}

// トースト通知の表示
function showToast(message, type = 'info') {
  // 既存のトーストを削除
  const existingToast = document.querySelector('.favorite-toast');
  if (existingToast) {
    existingToast.remove();
  }

  // トースト要素を作成
  const toast = document.createElement('div');
  toast.className = `favorite-toast fixed top-4 right-4 z-50 px-4 py-2 rounded-lg shadow-lg max-w-xs transform transition-all duration-300 translate-x-full opacity-0`;
  
  // タイプに応じたスタイル
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

  // アニメーション表示
  setTimeout(() => {
    toast.classList.remove('translate-x-full', 'opacity-0');
  }, 100);

  // 3秒後に自動削除
  setTimeout(() => {
    toast.classList.add('translate-x-full', 'opacity-0');
    setTimeout(() => {
      if (toast.parentNode) {
        toast.remove();
      }
    }, 300);
  }, 3000);
}

// CSRFトークンを取得（utils.jsのグローバル関数を使用）

// グローバル関数として公開（インライン呼び出し用）
window.toggleFavorite = toggleFavorite;