import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "filterTypeSelect",
    "filterTypeHidden",
    "detailLabel",
    "giftPersonSelect",
    "relationshipSelect",
    "genderSelect",
    "ageSelect",
    "eventSelect",
    "giftItemCategorySelect",
    "publicSelect",
    "giftDirectionSelect",
    "placeholder"
  ]

  connect() {
    this.update()
  }

  update() {
    const selectedType = this.hasFilterTypeSelectTarget ? this.filterTypeSelectTarget.value : ""

    if (this.hasFilterTypeHiddenTarget) {
      this.filterTypeHiddenTarget.value = selectedType
    }

    if (this.hasGiftPersonSelectTarget) this.hide(this.giftPersonSelectTarget)
    if (this.hasRelationshipSelectTarget) this.hide(this.relationshipSelectTarget)
    if (this.hasGenderSelectTarget) this.hide(this.genderSelectTarget)
    if (this.hasAgeSelectTarget) this.hide(this.ageSelectTarget)
    if (this.hasEventSelectTarget) this.hide(this.eventSelectTarget)
    if (this.hasGiftItemCategorySelectTarget) this.hide(this.giftItemCategorySelectTarget)
    if (this.hasPublicSelectTarget) this.hide(this.publicSelectTarget)
    if (this.hasGiftDirectionSelectTarget) this.hide(this.giftDirectionSelectTarget)
    if (this.hasPlaceholderTarget) this.hide(this.placeholderTarget)

    // 種類ごとに表示し、無関係なフィールドをクリア
    if (selectedType === "gift_person") {
      // ギフト相手のセレクトのみ表示し、現在の値は保持
      if (this.hasGiftPersonSelectTarget) this.show(this.giftPersonSelectTarget)
      if (this.hasRelationshipSelectTarget) this.clearValue(this.relationshipSelectTarget)
      if (this.hasEventSelectTarget) this.clearValue(this.eventSelectTarget)
      if (this.hasPublicSelectTarget) this.clearValue(this.publicSelectTarget)
      if (this.hasGiftDirectionSelectTarget) this.clearValue(this.giftDirectionSelectTarget)
    } else if (selectedType === "relationship") {
      // 関係性のセレクトのみ表示
      if (this.hasRelationshipSelectTarget) this.show(this.relationshipSelectTarget)
      if (this.hasGiftPersonSelectTarget) this.clearValue(this.giftPersonSelectTarget)
      if (this.hasGenderSelectTarget) this.clearValue(this.genderSelectTarget)
      if (this.hasAgeSelectTarget) this.clearValue(this.ageSelectTarget)
      if (this.hasEventSelectTarget) this.clearValue(this.eventSelectTarget)
      if (this.hasGiftItemCategorySelectTarget) this.clearValue(this.giftItemCategorySelectTarget)
      if (this.hasPublicSelectTarget) this.clearValue(this.publicSelectTarget)
      if (this.hasGiftDirectionSelectTarget) this.clearValue(this.giftDirectionSelectTarget)
    } else if (selectedType === "age") {
      // 年齢のセレクトのみ表示
      if (this.hasAgeSelectTarget) this.show(this.ageSelectTarget)
      if (this.hasGiftPersonSelectTarget) this.clearValue(this.giftPersonSelectTarget)
      if (this.hasRelationshipSelectTarget) this.clearValue(this.relationshipSelectTarget)
      if (this.hasGenderSelectTarget) this.clearValue(this.genderSelectTarget)
      if (this.hasEventSelectTarget) this.clearValue(this.eventSelectTarget)
      if (this.hasGiftItemCategorySelectTarget) this.clearValue(this.giftItemCategorySelectTarget)
      if (this.hasPublicSelectTarget) this.clearValue(this.publicSelectTarget)
      if (this.hasGiftDirectionSelectTarget) this.clearValue(this.giftDirectionSelectTarget)
    } else if (selectedType === "gender") {
      // 性別のセレクトのみ表示
      if (this.hasGenderSelectTarget) this.show(this.genderSelectTarget)
      if (this.hasGiftPersonSelectTarget) this.clearValue(this.giftPersonSelectTarget)
      if (this.hasRelationshipSelectTarget) this.clearValue(this.relationshipSelectTarget)
      if (this.hasAgeSelectTarget) this.clearValue(this.ageSelectTarget)
      if (this.hasEventSelectTarget) this.clearValue(this.eventSelectTarget)
      if (this.hasGiftItemCategorySelectTarget) this.clearValue(this.giftItemCategorySelectTarget)
      if (this.hasPublicSelectTarget) this.clearValue(this.publicSelectTarget)
      if (this.hasGiftDirectionSelectTarget) this.clearValue(this.giftDirectionSelectTarget)
    } else if (selectedType === "event") {
      // イベントのセレクトのみ表示
      if (this.hasEventSelectTarget) this.show(this.eventSelectTarget)
      if (this.hasGiftPersonSelectTarget) this.clearValue(this.giftPersonSelectTarget)
      if (this.hasRelationshipSelectTarget) this.clearValue(this.relationshipSelectTarget)
      if (this.hasGenderSelectTarget) this.clearValue(this.genderSelectTarget)
      if (this.hasAgeSelectTarget) this.clearValue(this.ageSelectTarget)
      if (this.hasGiftItemCategorySelectTarget) this.clearValue(this.giftItemCategorySelectTarget)
      if (this.hasPublicSelectTarget) this.clearValue(this.publicSelectTarget)
      if (this.hasGiftDirectionSelectTarget) this.clearValue(this.giftDirectionSelectTarget)
    } else if (selectedType === "gift_item_category") {
      // アイテムカテゴリのセレクトのみ表示
      if (this.hasGiftItemCategorySelectTarget) this.show(this.giftItemCategorySelectTarget)
      if (this.hasGiftPersonSelectTarget) this.clearValue(this.giftPersonSelectTarget)
      if (this.hasRelationshipSelectTarget) this.clearValue(this.relationshipSelectTarget)
      if (this.hasGenderSelectTarget) this.clearValue(this.genderSelectTarget)
      if (this.hasAgeSelectTarget) this.clearValue(this.ageSelectTarget)
      if (this.hasEventSelectTarget) this.clearValue(this.eventSelectTarget)
      if (this.hasPublicSelectTarget) this.clearValue(this.publicSelectTarget)
      if (this.hasGiftDirectionSelectTarget) this.clearValue(this.giftDirectionSelectTarget)
    } else if (selectedType === "is_public") {
      // 公開設定のセレクトのみ表示
      if (this.hasPublicSelectTarget) this.show(this.publicSelectTarget)
      if (this.hasGiftPersonSelectTarget) this.clearValue(this.giftPersonSelectTarget)
      if (this.hasRelationshipSelectTarget) this.clearValue(this.relationshipSelectTarget)
      if (this.hasGenderSelectTarget) this.clearValue(this.genderSelectTarget)
      if (this.hasAgeSelectTarget) this.clearValue(this.ageSelectTarget)
      if (this.hasEventSelectTarget) this.clearValue(this.eventSelectTarget)
      if (this.hasGiftItemCategorySelectTarget) this.clearValue(this.giftItemCategorySelectTarget)
      if (this.hasGiftDirectionSelectTarget) this.clearValue(this.giftDirectionSelectTarget)
    } else if (selectedType === "gift_direction") {
      // ギフト種別のセレクトのみ表示
      if (this.hasGiftDirectionSelectTarget) this.show(this.giftDirectionSelectTarget)
      if (this.hasGiftPersonSelectTarget) this.clearValue(this.giftPersonSelectTarget)
      if (this.hasRelationshipSelectTarget) this.clearValue(this.relationshipSelectTarget)
      if (this.hasGenderSelectTarget) this.clearValue(this.genderSelectTarget)
      if (this.hasAgeSelectTarget) this.clearValue(this.ageSelectTarget)
      if (this.hasEventSelectTarget) this.clearValue(this.eventSelectTarget)
      if (this.hasGiftItemCategorySelectTarget) this.clearValue(this.giftItemCategorySelectTarget)
      if (this.hasPublicSelectTarget) this.clearValue(this.publicSelectTarget)
    } else {
      // フィルタ未選択
      if (this.hasPlaceholderTarget) this.show(this.placeholderTarget)
      if (this.hasGiftPersonSelectTarget) this.clearValue(this.giftPersonSelectTarget)
      if (this.hasRelationshipSelectTarget) this.clearValue(this.relationshipSelectTarget)
      if (this.hasGenderSelectTarget) this.clearValue(this.genderSelectTarget)
      if (this.hasAgeSelectTarget) this.clearValue(this.ageSelectTarget)
      if (this.hasEventSelectTarget) this.clearValue(this.eventSelectTarget)
      if (this.hasGiftItemCategorySelectTarget) this.clearValue(this.giftItemCategorySelectTarget)
      if (this.hasPublicSelectTarget) this.clearValue(this.publicSelectTarget)
      if (this.hasGiftDirectionSelectTarget) this.clearValue(this.giftDirectionSelectTarget)
    }

    this.updateLabelAssociation(selectedType)
  }

  show(element) {
    if (!element) return
    element.classList.remove("hidden")
    element.removeAttribute("aria-hidden")
    if (element.disabled !== undefined && !this.isPlaceholder(element)) {
      element.disabled = false
    }
  }

  hide(element) {
    if (!element) return
    element.classList.add("hidden")
    element.setAttribute("aria-hidden", "true")
    if (element.disabled !== undefined) element.disabled = true
  }

  clearValue(element) {
    if (!element) return
    if (element.tagName === "SELECT") {
      element.value = ""
    }
  }

  updateLabelAssociation(selectedType) {
    if (!this.hasDetailLabelTarget) return

    const targetElement = this.elementForType(selectedType)

    if (targetElement && targetElement.id) {
      this.detailLabelTarget.setAttribute("for", targetElement.id)
    } else {
      this.detailLabelTarget.removeAttribute("for")
    }
  }

  elementForType(selectedType) {
    switch (selectedType) {
      case "gift_person":
        return this.hasGiftPersonSelectTarget ? this.giftPersonSelectTarget : null
      case "relationship":
        return this.hasRelationshipSelectTarget ? this.relationshipSelectTarget : null
      case "gender":
        return this.hasGenderSelectTarget ? this.genderSelectTarget : null
      case "age":
        return this.hasAgeSelectTarget ? this.ageSelectTarget : null
      case "event":
        return this.hasEventSelectTarget ? this.eventSelectTarget : null
      case "gift_item_category":
        return this.hasGiftItemCategorySelectTarget ? this.giftItemCategorySelectTarget : null
      case "is_public":
        return this.hasPublicSelectTarget ? this.publicSelectTarget : null
      case "gift_direction":
        return this.hasGiftDirectionSelectTarget ? this.giftDirectionSelectTarget : null
      default:
        return !selectedType && this.hasPlaceholderTarget ? this.placeholderTarget : null
    }
  }

  isPlaceholder(element) {
    return element?.dataset?.dynamicFilterPlaceholder === "true"
  }
}
