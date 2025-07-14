// ギフト相手選択プルダウンの制御 - エンタープライズレベル実装
console.log('gift_person_form.js: スクリプト読み込み完了');

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

    const analysis = {
      timestamp: new Date().toISOString(),
      giftPeopleSelect: {
        exists: !!giftPeopleSelect,
        value: giftPeopleSelect?.value || 'N/A',
        options: giftPeopleSelect ? Array.from(giftPeopleSelect.options).map(opt => ({ value: opt.value, text: opt.text })) : []
      },
      newGiftPersonFields: {
        exists: !!newGiftPersonFields,
        visible: newGiftPersonFields ? !newGiftPersonFields.style.display.includes('none') : false,
        computedDisplay: newGiftPersonFields ? window.getComputedStyle(newGiftPersonFields).display : 'N/A',
        inlineStyle: newGiftPersonFields?.style.display || 'N/A'
      },
      errorFlag: {
        exists: !!errorFlag,
        hasError: errorFlag?.dataset.hasError === 'true'
      }
    };

    console.log('gift_person_form.js: DOM状態分析', analysis);
    return analysis;
  }

  // 表示状態の更新（HTMLの初期状態を尊重）
  updateFieldsVisibility(selectElement) {
    const newGiftPersonFields = document.querySelector(this.SELECTORS.newGiftPersonFields);
    
    if (!selectElement || !newGiftPersonFields) {
      console.warn('gift_person_form.js: 必要な要素が見つかりません', {
        selectElement: !!selectElement,
        newGiftPersonFields: !!newGiftPersonFields
      });
      return;
    }

    const shouldShowFields = selectElement.value === this.STATES.SHOW_NEW_FIELDS;
    const previousState = currentGiftPersonState.fieldsVisible;
    
    // 表示状態の更新
    if (shouldShowFields) {
      newGiftPersonFields.style.display = 'block';
      currentGiftPersonState.fieldsVisible = true;
    } else {
      newGiftPersonFields.style.display = 'none';
      currentGiftPersonState.fieldsVisible = false;
    }

    // 状態変更のログ
    console.log('gift_person_form.js: 表示状態更新', {
      selectValue: selectElement.value,
      shouldShowFields,
      previousState,
      newState: currentGiftPersonState.fieldsVisible,
      changed: previousState !== currentGiftPersonState.fieldsVisible
    });

    // 状態の更新
    currentGiftPersonState.selectedValue = selectElement.value;
    currentGiftPersonState.lastUpdateTime = new Date().toISOString();
  }

  // 初期化処理
  initialize() {
    console.log('gift_person_form.js: コントローラー初期化開始');
    
    // DOM状態の分析
    this.analyzeDOMState();
    
    // 要素の存在確認
    const giftPeopleSelect = document.querySelector(this.SELECTORS.giftPeopleSelect);
    const newGiftPersonFields = document.querySelector(this.SELECTORS.newGiftPersonFields);
    
    if (!giftPeopleSelect || !newGiftPersonFields) {
      console.warn('gift_person_form.js: 必要なDOM要素が見つかりません - 初期化をスキップ');
      return false;
    }

    // 現在の状態を分析して初期表示を決定
    const currentValue = giftPeopleSelect.value;
    const isCurrentlyVisible = !newGiftPersonFields.style.display.includes('none');
    
    console.log('gift_person_form.js: 初期状態', {
      currentValue,
      isCurrentlyVisible,
      shouldBeVisible: currentValue === this.STATES.SHOW_NEW_FIELDS
    });

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
    console.log('gift_person_form.js: 既に初期化済み');
    return;
  }

  console.log('gift_person_form.js: イベントデリゲーション初期化開始');

  // ドキュメント全体でchangeイベントを捕捉（プルダウン用）
  document.addEventListener('change', function(event) {
    // ギフト相手選択プルダウンの変更を検出
    if (event.target && event.target.id === 'gift_people_select') {
      console.log('gift_person_form.js: プルダウン変更イベント検出', {
        newValue: event.target.value,
        previousValue: currentGiftPersonState.selectedValue
      });
      
      // 状態更新
      giftPersonController.updateFieldsVisibility(event.target);
    }
  });

  isGiftPersonFormInitialized = true;
  console.log('gift_person_form.js: イベントデリゲーション初期化完了');
}

// 包括的な初期化関数
function comprehensiveInitialize() {
  console.log('gift_person_form.js: 包括的初期化実行');
  
  // イベントデリゲーション初期化
  initializeGiftPersonFormDelegation();
  
  // コントローラー初期化
  const initSuccess = giftPersonController.initialize();
  
  if (!initSuccess) {
    console.warn('gift_person_form.js: 初期化失敗 - 遅延再試行をスケジュール');
    setTimeout(comprehensiveInitialize, 200);
  }
}

// 複数のタイミングで初期化を実行
document.addEventListener('DOMContentLoaded', comprehensiveInitialize);
document.addEventListener('turbo:load', comprehensiveInitialize);
document.addEventListener('turbo:render', comprehensiveInitialize);

// 遅延初期化
setTimeout(comprehensiveInitialize, 150);

// 緊急措置：2秒後に強制初期化
setTimeout(() => {
  if (!isGiftPersonFormInitialized) {
    console.warn('gift_person_form.js: 緊急措置による強制初期化');
    comprehensiveInitialize();
  }
}, 2000);

// グローバルデバッグ関数（開発用）
window.debugGiftPersonForm = function() {
  console.log('=== ギフト相手フォーム デバッグ情報 ===');
  console.log('初期化状態:', isGiftPersonFormInitialized);
  console.log('現在の状態:', currentGiftPersonState);
  giftPersonController.analyzeDOMState();
};