import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "filterTypeSelect",
    "filterTypeHidden",
    "giftPersonSelect",
    "relationshipSelect",
    "eventSelect",
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
    if (this.hasEventSelectTarget) this.hide(this.eventSelectTarget)
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
      if (this.hasEventSelectTarget) this.clearValue(this.eventSelectTarget)
      if (this.hasPublicSelectTarget) this.clearValue(this.publicSelectTarget)
      if (this.hasGiftDirectionSelectTarget) this.clearValue(this.giftDirectionSelectTarget)
    } else if (selectedType === "event") {
      // イベントのセレクトのみ表示
      if (this.hasEventSelectTarget) this.show(this.eventSelectTarget)
      if (this.hasGiftPersonSelectTarget) this.clearValue(this.giftPersonSelectTarget)
      if (this.hasRelationshipSelectTarget) this.clearValue(this.relationshipSelectTarget)
      if (this.hasPublicSelectTarget) this.clearValue(this.publicSelectTarget)
      if (this.hasGiftDirectionSelectTarget) this.clearValue(this.giftDirectionSelectTarget)
    } else if (selectedType === "is_public") {
      // 公開設定のセレクトのみ表示
      if (this.hasPublicSelectTarget) this.show(this.publicSelectTarget)
      if (this.hasGiftPersonSelectTarget) this.clearValue(this.giftPersonSelectTarget)
      if (this.hasRelationshipSelectTarget) this.clearValue(this.relationshipSelectTarget)
      if (this.hasEventSelectTarget) this.clearValue(this.eventSelectTarget)
      if (this.hasGiftDirectionSelectTarget) this.clearValue(this.giftDirectionSelectTarget)
    } else if (selectedType === "gift_direction") {
      // ギフト種別のセレクトのみ表示
      if (this.hasGiftDirectionSelectTarget) this.show(this.giftDirectionSelectTarget)
      if (this.hasGiftPersonSelectTarget) this.clearValue(this.giftPersonSelectTarget)
      if (this.hasRelationshipSelectTarget) this.clearValue(this.relationshipSelectTarget)
      if (this.hasEventSelectTarget) this.clearValue(this.eventSelectTarget)
      if (this.hasPublicSelectTarget) this.clearValue(this.publicSelectTarget)
    } else {
      // フィルタ未選択
      if (this.hasPlaceholderTarget) this.show(this.placeholderTarget)
      if (this.hasGiftPersonSelectTarget) this.clearValue(this.giftPersonSelectTarget)
      if (this.hasRelationshipSelectTarget) this.clearValue(this.relationshipSelectTarget)
      if (this.hasEventSelectTarget) this.clearValue(this.eventSelectTarget)
      if (this.hasPublicSelectTarget) this.clearValue(this.publicSelectTarget)
      if (this.hasGiftDirectionSelectTarget) this.clearValue(this.giftDirectionSelectTarget)
    }
  }

  show(element) {
    if (!element) return
    element.classList.remove("hidden")
    element.removeAttribute("aria-hidden")
    if (element.disabled !== undefined) element.disabled = false
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
}
