// 汎用オートコンプリート機能

class AutocompleteManager {
  constructor(inputSelector, options = {}) {
    this.inputSelector = inputSelector;
    this.options = {
      minLength: 1,
      debounceDelay: 300,
      maxResults: 10,
      endpoint: '/autocomplete',
      ...options
    };
    
    this.input = null;
    this.dropdown = null;
    this.loading = null;
    this.form = null;
    this.currentRequest = null;
    this.searchTimeout = null;
    this.isInitialized = false;
  }

  // 初期化
  initialize() {
    if (this.isInitialized) return true;

    this.input = document.querySelector(this.inputSelector);
    if (!this.input) return false;

    this.dropdown = document.querySelector(this.options.dropdownSelector);
    this.loading = document.querySelector(this.options.loadingSelector);
    this.form = this.input.closest('form');

    if (!this.dropdown || !this.loading) return false;

    this.setupEventListeners();
    this.isInitialized = true;
    return true;
  }

  // イベントリスナーの設定
  setupEventListeners() {
    // 入力イベント
    this.input.addEventListener('input', (e) => {
      const query = e.target.value.trim();
      this.handleInput(query);
    });

    // キーボードナビゲーション
    this.input.addEventListener('keydown', (e) => {
      this.handleKeyNavigation(e);
    });

    // 外部クリックでドロップダウンを閉じる
    document.addEventListener('click', (e) => {
      if (!this.input.contains(e.target) && !this.dropdown.contains(e.target)) {
        this.hideDropdown();
      }
    });
  }

  // 入力処理
  handleInput(query) {
    clearTimeout(this.searchTimeout);

    if (query.length >= this.options.minLength) {
      this.searchTimeout = setTimeout(() => {
        this.performSearch(query);
      }, this.options.debounceDelay);
    } else {
      this.hideDropdown();
    }
  }

  // 検索実行
  async performSearch(query) {
    // 既存のリクエストをキャンセル
    if (this.currentRequest) {
      this.currentRequest.abort();
    }

    this.showLoading();
    this.currentRequest = new AbortController();

    try {
      const url = `${this.options.endpoint}?q=${encodeURIComponent(query)}`;
      const response = await fetch(url, {
        signal: this.currentRequest.signal,
        headers: window.getAPIHeaders ? window.getAPIHeaders() : {
          'Accept': 'application/json',
          'X-Requested-With': 'XMLHttpRequest'
        }
      });

      if (!response.ok) throw new Error('検索に失敗しました');

      const data = await response.json();
      this.hideLoading();
      this.displayResults(data.results || []);
    } catch (error) {
      if (error.name !== 'AbortError') {
        console.error('オートコンプリートエラー:', error);
        this.hideLoading();
        this.hideDropdown();
      }
    }
  }

  // 検索結果の表示
  displayResults(results) {
    if (results.length === 0) {
      this.hideDropdown();
      return;
    }

    const html = results.slice(0, this.options.maxResults).map(result => {
      return this.createResultItem(result);
    }).join('');

    this.dropdown.innerHTML = html;
    this.showDropdown();
    this.attachResultClickEvents();
  }

  // 結果アイテムの作成
  createResultItem(result) {
    const typeIcon = this.getTypeIcon(result.type);
    const typeLabel = this.getTypeLabel(result.type);
    
    return `
      <div class="autocomplete-item px-3 py-2 hover:bg-primary-50 cursor-pointer border-b border-gray-100 last:border-b-0" 
           data-display-text="${window.escapeHtml ? window.escapeHtml(result.display_text) : result.display_text}" 
           data-id="${result.id}">
        <div class="flex items-start space-x-2">
          <div class="flex-shrink-0 w-6 h-6 bg-primary-100 rounded-full flex items-center justify-center">
            <i class="${typeIcon} text-primary text-xs"></i>
          </div>
          <div class="flex-1 min-w-0">
            <div class="text-xs font-medium text-gray-900">
              ${result.search_highlight || (window.escapeHtml ? window.escapeHtml(result.display_text) : result.display_text)}
            </div>
            <div class="text-xs text-gray-500 mt-0.5">
              ${typeLabel}
            </div>
          </div>
        </div>
      </div>
    `;
  }

  // 結果クリックイベントの設定
  attachResultClickEvents() {
    this.dropdown.querySelectorAll('.autocomplete-item').forEach(item => {
      item.addEventListener('click', () => {
        const displayText = item.dataset.displayText;
        this.input.value = displayText;
        this.hideDropdown();
        if (this.form) {
          this.form.submit();
        }
      });
    });
  }

  // キーボードナビゲーション
  handleKeyNavigation(e) {
    const items = this.dropdown.querySelectorAll('.autocomplete-item');
    const activeItem = this.dropdown.querySelector('.autocomplete-item.bg-primary-100');
    
    switch (e.key) {
      case 'ArrowDown':
        e.preventDefault();
        if (activeItem) {
          activeItem.classList.remove('bg-primary-100');
          const next = activeItem.nextElementSibling || items[0];
          next.classList.add('bg-primary-100');
        } else if (items.length > 0) {
          items[0].classList.add('bg-primary-100');
        }
        break;
        
      case 'ArrowUp':
        e.preventDefault();
        if (activeItem) {
          activeItem.classList.remove('bg-primary-100');
          const prev = activeItem.previousElementSibling || items[items.length - 1];
          prev.classList.add('bg-primary-100');
        } else if (items.length > 0) {
          items[items.length - 1].classList.add('bg-primary-100');
        }
        break;
        
      case 'Enter':
        if (activeItem) {
          e.preventDefault();
          activeItem.click();
        }
        break;
        
      case 'Escape':
        this.hideDropdown();
        break;
    }
  }

  // タイプ別アイコン
  getTypeIcon(type) {
    const icons = {
      item: 'fas fa-gift',
      memo: 'fas fa-sticky-note',
      user: 'fas fa-user',
      event: 'fas fa-calendar',
      ...this.options.typeIcons
    };
    return icons[type] || 'fas fa-search';
  }

  // タイプ別ラベル
  getTypeLabel(type) {
    const labels = {
      item: 'アイテム',
      memo: 'メモ',
      user: 'ユーザー',
      event: 'イベント',
      ...this.options.typeLabels
    };
    return labels[type] || '検索';
  }



  hideLoading() {
    if (this.loading) {
      this.loading.classList.add('hidden');
    }
  }

  // ドロップダウン表示
  showDropdown() {
    if (this.dropdown) {
      this.dropdown.classList.remove('hidden');
    }
  }

  hideDropdown() {
    if (this.dropdown) {
      this.dropdown.classList.add('hidden');
    }
  }

  // クリーンアップ
  cleanup() {
    if (this.currentRequest) {
      this.currentRequest.abort();
    }
    if (this.searchTimeout) {
      clearTimeout(this.searchTimeout);
    }
    this.isInitialized = false;
  }
}

// ギフト記録専用のシンプルなオートコンプリート
function initializeGiftRecordsAutocomplete() {
  console.log('🔍 [AUTOCOMPLETE] 初期化開始:', {
    timestamp: Date.now(),
    readyState: document.readyState,
    url: window.location.pathname
  });

  let searchTimeout;
  let currentRequest;
  
  const searchInput = document.getElementById('gift-records-search-input');
  const dropdown = document.getElementById('gift-records-autocomplete-dropdown');
  const loading = document.getElementById('gift-records-search-loading');
  
  console.log('🔍 [AUTOCOMPLETE] DOM要素チェック:', {
    searchInput: !!searchInput,
    dropdown: !!dropdown,
    loading: !!loading,
    searchInputValue: searchInput?.value || 'N/A',
    searchInputId: searchInput?.id || 'N/A'
  });
  
  if (!searchInput || !dropdown || !loading) {
    console.error('🔍 [AUTOCOMPLETE] 必要なDOM要素が見つかりません');
    return false;
  }
  
  // 既に初期化済みの場合はスキップ
  if (searchInput.dataset.autocompleteInitialized === 'true') {
    console.log('🔍 [AUTOCOMPLETE] 既に初期化済み');
    return true;
  }
  
  const form = searchInput.closest('form');
  if (!form) {
    console.error('🔍 [AUTOCOMPLETE] フォーム要素が見つかりません');
    return false;
  }
  
  console.log('🔍 [AUTOCOMPLETE] フォーム要素確認完了');
  
  // 検索入力処理
  searchInput.addEventListener('input', function(e) {
    const query = e.target.value.trim();
    
    console.log('🔍 [AUTOCOMPLETE] 入力イベント:', {
      query,
      queryLength: query.length,
      timestamp: Date.now()
    });
    
    clearTimeout(searchTimeout);
    
    if (query.length >= 1) {
      console.log('🔍 [AUTOCOMPLETE] オートコンプリート実行をスケジュール');
      searchTimeout = setTimeout(() => performAutocomplete(query), 300);
    } else {
      console.log('🔍 [AUTOCOMPLETE] クエリが短すぎるため、ドロップダウンを隠す');
      hideDropdown();
    }
  });
  
  console.log('🔍 [AUTOCOMPLETE] inputイベントリスナー設定完了');

  // オートコンプリート実行
  function performAutocomplete(query) {
    console.log('🔍 [AUTOCOMPLETE] オートコンプリート実行開始:', { query });
    
    if (currentRequest) {
      console.log('🔍 [AUTOCOMPLETE] 既存のリクエストをキャンセル');
      currentRequest.abort();
    }

    showLoading();
    currentRequest = new AbortController();
    
    const headers = window.getAPIHeaders ? window.getAPIHeaders() : {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
      'X-Requested-With': 'XMLHttpRequest',
      'X-CSRF-Token': window.getCSRFToken ? window.getCSRFToken() : ''
    };
    
    const apiUrl = `/gift_records/autocomplete?q=${encodeURIComponent(query)}`;
    console.log('🔍 [AUTOCOMPLETE] APIリクエスト:', { 
      url: apiUrl, 
      headers: Object.keys(headers) 
    });
    
    fetch(apiUrl, {
      signal: currentRequest.signal,
      headers: headers
    })
    .then(response => {
      console.log('🔍 [AUTOCOMPLETE] レスポンス受信:', { 
        status: response.status, 
        ok: response.ok 
      });
      if (!response.ok) throw new Error(`HTTP ${response.status}: ${response.statusText}`);
      return response.json();
    })
    .then(data => {
      console.log('🔍 [AUTOCOMPLETE] データ受信:', { 
        results: data.results?.length || 0,
        data: data 
      });
      hideLoading();
      displayResults(data.results || []);
    })
    .catch(error => {
      if (error.name !== 'AbortError') {
        console.error('🔍 [AUTOCOMPLETE] エラー:', error);
        hideLoading();
        hideDropdown();
      }
    });
  }

  // 検索結果表示
  function displayResults(results) {
    console.log('🔍 [AUTOCOMPLETE] 検索結果表示:', { 
      resultsCount: results.length,
      results: results 
    });
    
    if (results.length === 0) {
      console.log('🔍 [AUTOCOMPLETE] 結果なし、ドロップダウンを隠す');
      hideDropdown();
      return;
    }

    const html = results.map(result => {
      const typeIcon = getTypeIcon(result.type);
      const typeLabel = getTypeLabel(result.type);
      const displayText = window.escapeHtml ? window.escapeHtml(result.display_text) : result.display_text;
      
      return `
        <div class="autocomplete-item px-3 py-2 hover:bg-primary-50 cursor-pointer border-b border-gray-100 last:border-b-0" 
             data-display-text="${displayText}" 
             data-id="${result.id}">
          <div class="flex items-start space-x-2">
            <div class="flex-shrink-0 w-6 h-6 bg-primary-100 rounded-full flex items-center justify-center">
              <i class="${typeIcon} text-primary text-xs"></i>
            </div>
            <div class="flex-1 min-w-0">
              <div class="text-xs font-medium text-gray-900">
                ${result.search_highlight || displayText}
              </div>
              <div class="text-xs text-gray-500 mt-0.5">
                ${typeLabel}
              </div>
            </div>
          </div>
        </div>
      `;
    }).join('');

    dropdown.innerHTML = html;
    console.log('🔍 [AUTOCOMPLETE] HTMLセット完了、ドロップダウン表示');
    showDropdown();
    
    // クリックイベントの追加
    const items = dropdown.querySelectorAll('.autocomplete-item');
    console.log('🔍 [AUTOCOMPLETE] クリックイベント設定:', { itemCount: items.length });
    
    items.forEach(item => {
      item.addEventListener('click', function() {
        const displayText = this.dataset.displayText;
        searchInput.value = displayText;
        hideDropdown();
        form.submit();
      });
    });
  }

  // タイプ別アイコン
  function getTypeIcon(type) {
    switch(type) {
      case 'item': return 'fas fa-gift';
      case 'memo': return 'fas fa-sticky-note';
      default: return 'fas fa-search';
    }
  }

  // タイプ別ラベル
  function getTypeLabel(type) {
    switch(type) {
      case 'item': return 'アイテム';
      case 'memo': return 'メモ';
      default: return '検索';
    }
  }

  // ローディング表示
  function showLoading() {
    console.log('🔍 [AUTOCOMPLETE] ローディング表示');
    loading.classList.remove('hidden');
  }

  function hideLoading() {
    console.log('🔍 [AUTOCOMPLETE] ローディング非表示');
    loading.classList.add('hidden');
  }

  // ドロップダウン表示
  function showDropdown() {
    console.log('🔍 [AUTOCOMPLETE] ドロップダウン表示');
    dropdown.classList.remove('hidden');
  }

  function hideDropdown() {
    console.log('🔍 [AUTOCOMPLETE] ドロップダウン非表示');
    dropdown.classList.add('hidden');
  }

  // 外部クリック時にドロップダウンを閉じる
  document.addEventListener('click', function(e) {
    if (!searchInput.contains(e.target) && !dropdown.contains(e.target)) {
      hideDropdown();
    }
  });

  // キーボードナビゲーション
  searchInput.addEventListener('keydown', function(e) {
    const items = dropdown.querySelectorAll('.autocomplete-item');
    const activeItem = dropdown.querySelector('.autocomplete-item.bg-primary-100');
    
    switch (e.key) {
      case 'ArrowDown':
        e.preventDefault();
        if (activeItem) {
          activeItem.classList.remove('bg-primary-100');
          const next = activeItem.nextElementSibling || items[0];
          next.classList.add('bg-primary-100');
        } else if (items.length > 0) {
          items[0].classList.add('bg-primary-100');
        }
        break;
        
      case 'ArrowUp':
        e.preventDefault();
        if (activeItem) {
          activeItem.classList.remove('bg-primary-100');
          const prev = activeItem.previousElementSibling || items[items.length - 1];
          prev.classList.add('bg-primary-100');
        } else if (items.length > 0) {
          items[items.length - 1].classList.add('bg-primary-100');
        }
        break;
        
      case 'Enter':
        if (activeItem) {
          e.preventDefault();
          activeItem.click();
        }
        break;
        
      case 'Escape':
        hideDropdown();
        break;
    }
  });

  // 初期化完了をマーク
  searchInput.dataset.autocompleteInitialized = 'true';
  
  console.log('🔍 [AUTOCOMPLETE] 初期化完了！');
  return true;
}

// クリーンアップ関数
function cleanupGiftRecordsAutocomplete() {
  const searchInput = document.getElementById('gift-records-search-input');
  if (searchInput) {
    searchInput.dataset.autocompleteInitialized = 'false';
  }
}

// Turbo対応初期化
console.log('🔍 [AUTOCOMPLETE] 初期化戦略選択:', {
  hasTurboInit: !!window.turboInit,
  readyState: document.readyState,
  timestamp: Date.now()
});

if (window.turboInit) {
  console.log('🔍 [AUTOCOMPLETE] turboInit使用');
  window.turboInit(() => {
    console.log('🔍 [AUTOCOMPLETE] turboInit実行');
    // ページ離脱時のクリーンアップ
    document.addEventListener('turbo:before-visit', cleanupGiftRecordsAutocomplete);
    
    return initializeGiftRecordsAutocomplete();
  });
} else {
  console.log('🔍 [AUTOCOMPLETE] 標準初期化使用');
  // フォールバック: 直接初期化
  document.addEventListener('DOMContentLoaded', () => {
    console.log('🔍 [AUTOCOMPLETE] DOMContentLoaded実行');
    initializeGiftRecordsAutocomplete();
  });
  document.addEventListener('turbo:load', () => {
    console.log('🔍 [AUTOCOMPLETE] turbo:load実行');
    initializeGiftRecordsAutocomplete();
  });
  
  // 即座に試行
  if (document.readyState !== 'loading') {
    console.log('🔍 [AUTOCOMPLETE] 即座に初期化実行');
    initializeGiftRecordsAutocomplete();
  }
}

// グローバルに公開（後方互換性のため）
window.AutocompleteManager = AutocompleteManager;
