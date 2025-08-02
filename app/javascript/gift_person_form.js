// ギフト相手選択プルダウンの制御

// グローバル状態管理
let isGiftPersonFormInitialized = false;
let currentGiftPersonState = {
  selectedValue: null,
  fieldsVisible: false,
  lastUpdateTime: null
};

// 状態管理クラス
class GiftPersonFormController {
  constructor() {
    this.SELECTORS = {
      giftPeopleSelect: '#gift_people_select',
      newGiftPersonFields: '#new_gift_person_fields',
      errorFlag: '#gift_person_error_flag'
    };
    
    this.STATES = {
      SHOW_NEW_FIELDS: 'new',
      HIDE_NEW_FIELDS: 'existing'
    };
  }

  // DOM状態の詳細分析
  analyzeDOMState() {
    const giftPeopleSelect = document.querySelector(this.SELECTORS.giftPeopleSelect);
    const newGiftPersonFields = document.querySelector(this.SELECTORS.newGiftPersonFields);
    const errorFlag = document.querySelector(this.SELECTORS.errorFlag);

    return {
      giftPeopleSelect: !!giftPeopleSelect,
      newGiftPersonFields: !!newGiftPersonFields,
      errorFlag: !!errorFlag
    };
  }

  // 表示状態の更新（HTMLの初期状態を尊重）
  updateFieldsVisibility(selectElement) {
    const newGiftPersonFields = document.querySelector(this.SELECTORS.newGiftPersonFields);
    
    if (!selectElement || !newGiftPersonFields) {
      return;
    }

    const shouldShowFields = selectElement.value === this.STATES.SHOW_NEW_FIELDS;
    
    // 表示状態の更新
    if (shouldShowFields) {
      newGiftPersonFields.style.display = 'block';
      currentGiftPersonState.fieldsVisible = true;
    } else {
      newGiftPersonFields.style.display = 'none';
      currentGiftPersonState.fieldsVisible = false;
    }

    // 状態の更新
    currentGiftPersonState.selectedValue = selectElement.value;
    currentGiftPersonState.lastUpdateTime = new Date().toISOString();
  }

  // 初期化処理
  initialize() {
    // 要素の存在確認
    const giftPeopleSelect = document.querySelector(this.SELECTORS.giftPeopleSelect);
    const newGiftPersonFields = document.querySelector(this.SELECTORS.newGiftPersonFields);
    
    if (!giftPeopleSelect || !newGiftPersonFields) {
      return false;
    }

    // HTMLの初期状態を尊重しつつ、論理的に正しい状態に調整
    this.updateFieldsVisibility(giftPeopleSelect);

    return true;
  }
}

// グローバルコントローラーインスタンス
const giftPersonController = new GiftPersonFormController();

// イベントデリゲーションによる堅牢な実装
function initializeGiftPersonFormDelegation() {
  if (isGiftPersonFormInitialized) {
    return;
  }

  // ドキュメント全体でchangeイベントを捕捉（プルダウン用）
  document.addEventListener('change', function(event) {
    // ギフト相手選択プルダウンの変更を検出
    if (event.target && event.target.id === 'gift_people_select') {
      // 状態更新
      giftPersonController.updateFieldsVisibility(event.target);
    }
  });

  isGiftPersonFormInitialized = true;
}

// 包括的な初期化関数
function comprehensiveInitialize() {
  // イベントデリゲーション初期化
  initializeGiftPersonFormDelegation();
  
  // コントローラー初期化
  const initSuccess = giftPersonController.initialize();
  
  if (!initSuccess) {
    setTimeout(comprehensiveInitialize, 200);
    return false;
  }
  
  return true;
}

// Turbo対応初期化
window.turboInit(comprehensiveInitialize);

// グローバルデバッグ関数（開発用）
window.debugGiftPersonForm = function() {
  return {
    initialized: isGiftPersonFormInitialized,
    state: currentGiftPersonState,
    domState: giftPersonController.analyzeDOMState()
  };
};