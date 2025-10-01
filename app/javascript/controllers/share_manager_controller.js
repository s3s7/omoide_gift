import { Controller } from "@hotwired/stimulus"
import { getAPIHeaders, escapeHtml } from "../utils"

// Connects to data-controller="share-manager"
export default class extends Controller {
  static targets = ["modal", "preview", "textPreview", "lengthCounter"]
  static values = {
    dismissEndpoint: { type: String, default: "/gift_records/dismiss_share" },
    maxLength: { type: Number, default: 280 },
    itemName: String,
    giftPersonName: String,
    relationshipName: String,
    eventName: String,
    memo: String,
    hasImage: Boolean,
    imageUrl: String
  }

  connect() {
    this.shareGiftRecord = null
    this.lastCreatedGiftRecordId = null

    // Handle initial share from URL params
    const params = new URLSearchParams(window.location.search)
    const giftRecordId = params.get("gift_record_id")
    if (params.get("share_confirm") === "true" && giftRecordId) {
      this.lastCreatedGiftRecordId = parseInt(giftRecordId, 10)
      // Prefer server-provided details via data-* values
      if (this.hasItemNameValue || this.hasGiftPersonNameValue || this.hasEventNameValue || this.hasRelationshipNameValue || this.hasMemoValue) {
        this.shareGiftRecord = {
          id: this.lastCreatedGiftRecordId,
          itemName: this.itemNameValue,
          giftPersonName: this.giftPersonNameValue,
          relationshipName: this.relationshipNameValue,
          eventName: this.eventNameValue,
          memo: this.memoValue,
          hasImage: this.hasImageValue,
          imageUrl: this.imageUrlValue
        }
      } else {
        this.shareGiftRecord = { id: this.lastCreatedGiftRecordId }
      }
      this.open()
    }

 
    if (!this.shareGiftRecord && (this.hasItemNameValue || this.hasGiftPersonNameValue || this.hasEventNameValue || this.hasRelationshipNameValue || this.hasMemoValue)) {
      this.shareGiftRecord = {
        id: this.lastCreatedGiftRecordId,
        itemName: this.itemNameValue,
        giftPersonName: this.giftPersonNameValue,
        relationshipName: this.relationshipNameValue,
        eventName: this.eventNameValue,
        memo: this.memoValue,
        hasImage: this.hasImageValue,
        imageUrl: this.imageUrlValue
      }
    }

    // ESC to close
    this.boundEscHandler = (e) => {
      if (e.key === "Escape" && this.isVisible()) this.close()
    }
    document.addEventListener("keydown", this.boundEscHandler)
  }

  disconnect() {
    document.removeEventListener("keydown", this.boundEscHandler)
  }

  // Actions
  open() {
    if (!this.hasModalTarget) return
    this.updatePreview()
    this.updateTextPreview()
    this.modalTarget.classList.remove("hidden")
    // Let CSS classes control layout; avoid forcing flex here
    this.modalTarget.style.removeProperty("display")
    document.body.style.overflow = "hidden"
  }

  async close() {
    if (this.hasModalTarget) {
      this.modalTarget.classList.add("hidden")
      this.modalTarget.style.display = "none"
      document.body.style.overflow = "auto"
    }

    // Dismiss record on server (best-effort)
    const id = this.shareGiftRecord?.id || this.lastCreatedGiftRecordId
    if (id) {
      try {
        await fetch(this.dismissEndpointValue, {
          method: "POST",
          headers: getAPIHeaders(),
          body: JSON.stringify({ gift_record_id: id })
        })
      } catch (_) {
        // ignore
      }
    }

    // Redirect to list without params
    window.location.href = "/gift_records"
  }

  shareToX() {
    if (!this.shareGiftRecord && this.lastCreatedGiftRecordId) {
      this.shareGiftRecord = { id: this.lastCreatedGiftRecordId }
    }

    const text = this.generateShareText(this.shareGiftRecord || {})
    const detailUrl = this.detailUrl()
    const tweetUrl = `https://x.com/intent/tweet?text=${encodeURIComponent(text)}&url=${encodeURIComponent(detailUrl)}`

    const width = 550
    const height = 420
    const left = (window.innerWidth - width) / 2
    const top = (window.innerHeight - height) / 2

    window.open(
      tweetUrl,
      "share-twitter",
      `width=${width},height=${height},left=${left},top=${top},resizable=yes,scrollbars=yes`
    )

    this.close()
  }

  // Helpers
  updatePreview() {
    if (!this.hasPreviewTarget) return
    const record = this.shareGiftRecord || {}
    
    const html = `
      <div class=\"flex items-start space-x-3\">
        <div class=\"flex-shrink-0 w-12 h-12 bg-primary-100 rounded-full flex items-center justify-center\">
          <i class=\"fas fa-gift text-primary\"></i>
        </div>
        <div class=\"flex-1 min-w-0\">
          <div class=\"text-sm font-medium text-gray-900\">${escapeHtml(record.itemName || "未設定")}</div>
          <div class=\"text-xs text-gray-500 mt-1\">
            <span class=\"inline-flex items-center\">
              <i class=\"fas fa-user mr-1\"></i>${escapeHtml(record.giftPersonName || "未設定")}
            </span>
            <span class=\"ml-3 inline-flex items-center\">
              <i class=\"fas fa-calendar mr-1\"></i>${escapeHtml(record.eventName || "未設定")}
            </span>
          </div>
        </div>
      </div>
    `
    this.previewTarget.innerHTML = html
  }

  updateTextPreview() {
    if (!this.hasTextPreviewTarget || !this.hasLengthCounterTarget) return
    const text = this.generateShareText(this.shareGiftRecord || {})
    this.textPreviewTarget.innerHTML = escapeHtml(text).replace(/\n/g, "<br>")
    this.lengthCounterTarget.textContent = text.length
    if (text.length > this.maxLengthValue) {
      this.lengthCounterTarget.classList.add("text-red-600")
      this.lengthCounterTarget.classList.remove("text-gray-500")
    } else {
      this.lengthCounterTarget.classList.remove("text-red-600")
      this.lengthCounterTarget.classList.add("text-gray-500")
    }
  }

  generateShareText(record) {
    let text = "✨ ギフト記録を更新しました！\n\n"
    text += `🎁 ギフトアイテム: ${record.itemName || "未設定"}\n`
    text += `👥 関係性: ${record.relationshipName || "未設定"}\n`
    text += `📅 イベント: ${record.eventName || "未設定"}\n`
    if (record.hasImage) text += "📸 画像付きの投稿です\n"
    if (record.memo) text += `📝 ${record.memo}\n`
    const eventTag = (record.eventName || "").replace(/\s+/g, "")
    text += "\n #思い出ギフト #ギフト記録 #プレゼント"
    if (eventTag) text += ` #${eventTag}`
    return text
  }

  detailUrl() {
    if (this.shareGiftRecord?.id) return `${window.location.origin}/gift_records/${this.shareGiftRecord.id}`
    if (this.lastCreatedGiftRecordId) return `${window.location.origin}/gift_records/${this.lastCreatedGiftRecordId}`
    return window.location.href
  }

  isVisible() {
    return this.hasModalTarget && !this.modalTarget.classList.contains("hidden")
  }

  csrfToken() {
    const meta = document.querySelector('meta[name=\"csrf-token\"]')
    return meta ? meta.getAttribute('content') : ''
  }

  escapeHtml(text) {
    const div = document.createElement('div')
    div.textContent = text || ''
    return div.innerHTML
  }
}
