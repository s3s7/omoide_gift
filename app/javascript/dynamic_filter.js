// 動的フィルター機能

class DynamicFilterManager {
  constructor(options = {}) {
    this.options = {
      filterTypeSelector: '#filter-type-select',
      filterTypeHiddenSelector: '#filter-type-hidden',
      placeholderSelector: '#filter-placeholder',
      ...options
    };
    
    this.filterTypeSelect = null;
    this.filterTypeHidden = null;
    this.placeholder = null;
    this.filterFields = new Map();
    this.isInitialized = false;
  }

  // 初期化
  initialize() {
    if (this.isInitialized) return true;

    this.filterTypeSelect = document.querySelector(this.options.filterTypeSelector);
    this.filterTypeHidden = document.querySelector(this.options.filterTypeHiddenSelector);
    this.placeholder = document.querySelector(this.options.placeholderSelector);

    if (!this.filterTypeSelect || !this.filterTypeHidden || !this.placeholder) {
      return false;
    }

    this.discoverFilterFields();
    this.setupEventListeners();
    this.updateFilterDisplay();
    
    this.isInitialized = true;
    return true;
  }

  // フィルターフィールドを自動発見
  discoverFilterFields() {
    // 一般的なフィルターフィールドを自動検出
    const commonSelectors = [
      '#relationship-select',  
      '#event-select',
      '#category-select',
      '#status-select'
    ];

    commonSelectors.forEach(selector => {
      const element = document.querySelector(selector);
      if (element) {
        // セレクターからタイプを推測
        const type = this.extractTypeFromSelector(selector);
        this.filterFields.set(type, element);
      }
    });

    // data属性からも検出
    document.querySelectorAll('[data-filter-type]').forEach(element => {
      const type = element.dataset.filterType;
      this.filterFields.set(type, element);
    });
  }

  // セレクターからフィルタータイプを抽出
  extractTypeFromSelector(selector) {
    if (selector.includes('relationship')) return 'relationship';
    if (selector.includes('event')) return 'event';
    if (selector.includes('category')) return 'category';
    if (selector.includes('status')) return 'status';
    return selector.replace(/[#-]/g, '');
  }

  // フィルターフィールドを手動で追加
  addFilterField(type, selector) {
    const element = document.querySelector(selector);
    if (element) {
      this.filterFields.set(type, element);
    }
  }

  // イベントリスナーの設定
  setupEventListeners() {
    this.filterTypeSelect.addEventListener('change', () => {
      this.updateFilterDisplay();
    });
  }

  // フィルター表示の更新
  updateFilterDisplay() {
    const selectedType = this.filterTypeSelect.value;
    
    // hidden fieldを更新
    this.filterTypeHidden.value = selectedType;
    
    // すべてのフィールドを非表示
    this.hideAllFields();
    
    // 選択されたタイプに応じた表示
    if (selectedType && this.filterFields.has(selectedType)) {
      this.showField(selectedType);
      this.clearOtherFields(selectedType);
    } else {
      this.showPlaceholder();
      this.clearAllFields();
    }
  }

  // すべてのフィールドを非表示
  hideAllFields() {
    this.placeholder.style.display = 'none';
    
    this.filterFields.forEach(element => {
      element.style.display = 'none';
    });
  }

  // 指定されたフィールドを表示
  showField(type) {
    const field = this.filterFields.get(type);
    if (field) {
      field.style.display = 'block';
    }
  }

  // プレースホルダーを表示
  showPlaceholder() {
    this.placeholder.style.display = 'block';
  }

  // 他のフィールドをクリア
  clearOtherFields(activeType) {
    this.filterFields.forEach((element, type) => {
      if (type !== activeType && element.tagName === 'SELECT') {
        element.value = '';
      }
    });
  }

  // すべてのフィールドをクリア
  clearAllFields() {
    this.filterFields.forEach(element => {
      if (element.tagName === 'SELECT') {
        element.value = '';
      }
    });
  }

  // 現在の選択状態を取得
  getCurrentState() {
    return {
      selectedType: this.filterTypeSelect.value,
      values: Array.from(this.filterFields.entries()).reduce((acc, [type, element]) => {
        if (element.tagName === 'SELECT') {
          acc[type] = element.value;
        }
        return acc;
      }, {})
    };
  }

  // 状態をリセット
  reset() {
    this.filterTypeSelect.value = '';
    this.clearAllFields();
    this.updateFilterDisplay();
  }
}

// ギフト記録ページ専用のシンプルな動的フィルター初期化
function initializeGiftRecordsDynamicFilter() {
  const filterTypeSelect = document.getElementById('filter-type-select');
  const filterTypeHidden = document.getElementById('filter-type-hidden');
  const relationshipSelect = document.getElementById('relationship-select');
  const eventSelect = document.getElementById('event-select');
  const placeholder = document.getElementById('filter-placeholder');
  
  if (!filterTypeSelect || !filterTypeHidden || !relationshipSelect || !eventSelect || !placeholder) {
    return false;
  }
  
  // 既に初期化済みの場合はスキップ
  if (filterTypeSelect.dataset.filterInitialized === 'true') {
    return true;
  }
  
  // 初期状態の設定
  function updateFilterDisplay() {
    const selectedType = filterTypeSelect.value;
    
    // hidden fieldを更新
    filterTypeHidden.value = selectedType;
    
    // すべて非表示にする
    relationshipSelect.style.display = 'none';
    eventSelect.style.display = 'none';
    placeholder.style.display = 'none';
    
    // 選択されたタイプに応じて表示
    if (selectedType === 'relationship') {
      relationshipSelect.style.display = 'block';
      // イベント選択をクリア
      eventSelect.value = '';
    } else if (selectedType === 'event') {
      eventSelect.style.display = 'block';
      // 関係性選択をクリア
      relationshipSelect.value = '';
    } else {
      placeholder.style.display = 'block';
      // 両方クリア
      relationshipSelect.value = '';
      eventSelect.value = '';
    }
  }
  
  // フィルタータイプ変更時の処理
  filterTypeSelect.addEventListener('change', updateFilterDisplay);
  
  // 初期表示の設定
  updateFilterDisplay();
  
  // 初期化完了をマーク
  filterTypeSelect.dataset.filterInitialized = 'true';
  
  return true;
}

// クリーンアップ関数
function cleanupGiftRecordsDynamicFilter() {
  const filterTypeSelect = document.getElementById('filter-type-select');
  if (filterTypeSelect) {
    filterTypeSelect.dataset.filterInitialized = 'false';
  }
}

// Turbo対応初期化
if (window.turboInit) {
  window.turboInit(() => {
    // ページ離脱時のクリーンアップ
    document.addEventListener('turbo:before-visit', cleanupGiftRecordsDynamicFilter);
    
    return initializeGiftRecordsDynamicFilter();
  });
} else {
  // フォールバック: 直接初期化
  document.addEventListener('DOMContentLoaded', initializeGiftRecordsDynamicFilter);
  document.addEventListener('turbo:load', initializeGiftRecordsDynamicFilter);
  
  // 即座に試行
  if (document.readyState !== 'loading') {
    initializeGiftRecordsDynamicFilter();
  }
}

// グローバルに公開（後方互換性のため）
window.DynamicFilterManager = DynamicFilterManager;