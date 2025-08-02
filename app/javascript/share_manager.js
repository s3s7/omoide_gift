// ギフト記録シェア機能

class ShareManager {
  constructor(options = {}) {
    this.options = {
      modalSelector: '#share-confirmation-modal',
      previewSelector: '#share-gift-preview',
      textPreviewSelector: '#share-text-preview',
      lengthCounterSelector: '#share-text-length',
      maxLength: 280,
      dismissEndpoint: '/gift_records/dismiss_share',
      ...options
    };
    
    this.modal = null;
    this.preview = null;
    this.textPreview = null;
    this.lengthCounter = null;
    this.shareGiftRecord = null;
    this.lastCreatedGiftRecordId = null;
    this.isInitialized = false;
  }

  // 初期化
  initialize() {
    if (this.isInitialized) return true;

    this.modal = document.querySelector(this.options.modalSelector);
    this.preview = document.querySelector(this.options.previewSelector);
    this.textPreview = document.querySelector(this.options.textPreviewSelector);
    this.lengthCounter = document.querySelector(this.options.lengthCounterSelector);

    // モーダルが存在しない場合は正常終了（シェア機能なしページ）
    if (!this.modal) {
      this.isInitialized = true;
      return true;
    }

    this.setupEventListeners();
    this.handleInitialShare();
    
    this.isInitialized = true;
    return true;
  }

  // イベントリスナーの設定
  setupEventListeners() {
    // ESCキーでモーダルを閉じる
    document.addEventListener('keydown', (e) => {
      if (e.key === 'Escape' && this.isModalVisible()) {
        this.closeModal();
      }
    });
  }

  // 初期シェアデータの処理
  handleInitialShare() {
    // URL パラメータから取得を試行
    const urlParams = new URLSearchParams(window.location.search);
    const giftRecordId = urlParams.get('gift_record_id');
    
    if (giftRecordId && urlParams.get('share_confirm') === 'true') {
      this.lastCreatedGiftRecordId = parseInt(giftRecordId);
      // 最小限のシェアデータを設定
      this.shareGiftRecord = {
        id: parseInt(giftRecordId)
      };
      this.showModal();
    }
  }

  // サーバーサイドからシェアデータを設定
  setShareData(giftRecord) {
    this.shareGiftRecord = giftRecord;
    this.lastCreatedGiftRecordId = giftRecord.id;
    this.showModal();
  }

  // モーダル表示
  showModal() {
    if (!this.shareGiftRecord || !this.modal) return;

    // プレビューコンテンツを生成
    this.updatePreview();
    
    // シェアテキストを生成して表示
    this.updateTextPreview();

    // モーダル表示（シンプルなDOM操作）
    this.modal.classList.remove('hidden');
    this.modal.style.display = 'flex';
    document.body.style.overflow = 'hidden';
  }

  // プレビューの更新
  updatePreview() {
    if (!this.preview || !this.shareGiftRecord) return;

    const previewHTML = `
      <div class="flex items-start space-x-3">
        <div class="flex-shrink-0 w-12 h-12 bg-primary-100 rounded-full flex items-center justify-center">
          <i class="fas fa-gift text-primary"></i>
        </div>
        <div class="flex-1 min-w-0">
          <div class="text-sm font-medium text-gray-900">
            ${this.escapeHtml(this.shareGiftRecord.itemName || '未設定')}
          </div>
          <div class="text-xs text-gray-500 mt-1">
            <span class="inline-flex items-center">
              <i class="fas fa-user mr-1"></i>
              ${this.escapeHtml(this.shareGiftRecord.giftPersonName || '未設定')}
            </span>
            <span class="ml-3 inline-flex items-center">
              <i class="fas fa-calendar mr-1"></i>
              ${this.shareGiftRecord.eventName || '未設定'}
            </span>
          </div>
        </div>
      </div>
    `;

    this.preview.innerHTML = previewHTML;
  }

  // テキストプレビューの更新
  updateTextPreview() {
    if (!this.textPreview || !this.lengthCounter) return;

    const shareText = this.generateShareText(this.shareGiftRecord);
    
    // 改行文字を<br>タグに変換してプレビュー表示
    const shareTextForDisplay = this.escapeHtml(shareText).replace(/\n/g, '<br>');
    this.textPreview.innerHTML = shareTextForDisplay;
    this.lengthCounter.textContent = shareText.length;

    // 文字数チェック
    if (shareText.length > this.options.maxLength) {
      this.lengthCounter.classList.add('text-red-600');
      this.lengthCounter.classList.remove('text-gray-500');
    } else {
      this.lengthCounter.classList.remove('text-red-600');
      this.lengthCounter.classList.add('text-gray-500');
    }
  }

  // シェアテキストの生成
  generateShareText(record) {
    let text = `✨ ギフト記録を更新しました！\n\n`;
    text += `🎁 ギフトアイテム: ${record.itemName || '未設定'}\n`;
    text += `👥 関係性: ${record.relationshipName || '未設定'}\n`;
    text += `📅 イベント: ${record.eventName || '未設定'}\n`;

    if (record.memo) {
      text += `📝 ${record.memo}\n`;
    }

    const eventTag = (record.eventName || '').replace(/\s+/g, '');
    text += `\n #思い出ギフト #ギフト記録 #プレゼント`;
    
    if (eventTag) {
      text += ` #${eventTag}`;
    }

    return text;
  }

  // Xでシェア
  shareToX() {
    if (!this.shareGiftRecord) return;

    const shareText = this.generateShareText(this.shareGiftRecord);
    
    // 詳細画面のURLを生成
    const detailUrl = this.getDetailUrl();
    const url = encodeURIComponent(detailUrl);
    const tweetUrl = `https://x.com/intent/tweet?text=${encodeURIComponent(shareText)}&url=${url}`;
    
    // 新しいウィンドウでXを開く
    const width = 550;
    const height = 420;
    const left = (window.innerWidth - width) / 2;
    const top = (window.innerHeight - height) / 2;
    
    window.open(
      tweetUrl,
      'share-twitter',
      `width=${width},height=${height},left=${left},top=${top},resizable=yes,scrollbars=yes`
    );
    
    this.closeModal();
  }

  // 詳細画面URLの生成
  getDetailUrl() {
    if (this.shareGiftRecord && this.shareGiftRecord.id) {
      return `${window.location.origin}/gift_records/${this.shareGiftRecord.id}`;
    } else if (this.lastCreatedGiftRecordId) {
      return `${window.location.origin}/gift_records/${this.lastCreatedGiftRecordId}`;
    } else {
      return window.location.href;
    }
  }

  // モーダルを閉じる
  async closeModal() {
    if (this.modal) {
      this.modal.classList.add('hidden');
      this.modal.style.display = 'none';
      document.body.style.overflow = 'auto';
    }
    
    // シェア拒否をサーバーに記録
    if (this.shareGiftRecord && this.shareGiftRecord.id) {
      try {
        await fetch(this.options.dismissEndpoint, {
          method: 'POST',
          headers: window.getAPIHeaders ? window.getAPIHeaders() : {
            'Content-Type': 'application/json',
            'X-CSRF-Token': window.getCSRFToken ? window.getCSRFToken() : '',
            'Accept': 'application/json'
          },
          body: JSON.stringify({ gift_record_id: this.shareGiftRecord.id })
        });
      } catch (error) {
        // エラーが発生してもページ遷移は実行
      }
    }
    
    // パラメータなしのURLに遷移
    window.location.href = '/gift_records';
  }

  // モーダルが表示されているかチェック
  isModalVisible() {
    if (!this.modal) return false;
    return !this.modal.classList.contains('hidden');
  }

  // HTMLエスケープ
  escapeHtml(text) {
    if (window.escapeHtml) {
      return window.escapeHtml(text);
    }
    
    const div = document.createElement('div');
    div.textContent = text;
    return div.innerHTML;
  }

  // クリーンアップ
  cleanup() {
    this.shareGiftRecord = null;
    this.lastCreatedGiftRecordId = null;
  }
}

// ギフト記録専用の初期化
function initializeGiftRecordsShare() {
  const shareManager = new ShareManager({
    modalSelector: '#share-confirmation-modal',
    previewSelector: '#share-gift-preview',
    textPreviewSelector: '#share-text-preview',
    lengthCounterSelector: '#share-text-length'
  });

  // グローバル関数として公開
  window.shareToX = () => shareManager.shareToX();
  window.closeShareModal = () => shareManager.closeModal();

  return shareManager.initialize();
}

// Turbo対応初期化
if (window.turboInit) {
  window.turboInit(() => {
    return initializeGiftRecordsShare();
  });
} else {
  // フォールバック: 直接初期化
  document.addEventListener('DOMContentLoaded', initializeGiftRecordsShare);
  document.addEventListener('turbo:load', initializeGiftRecordsShare);
  
  // 即座に試行
  if (document.readyState !== 'loading') {
    initializeGiftRecordsShare();
  }
}

// グローバルに公開
window.ShareManager = ShareManager;