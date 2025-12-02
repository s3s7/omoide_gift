import { Controller } from "@hotwired/stimulus"
import { showToast } from "../utils"

export default class extends Controller {
  static values = {
    messages: Array
  }

  connect() {
    this.renderMessages()
  }

  renderMessages() {
    if (!this.hasMessagesValue || !Array.isArray(this.messagesValue)) return

    this.messagesValue.forEach((payload = {}) => {
      const message = payload.message || payload.text || ""
      if (!message) return
      const type = this.normalizeType(payload.type)
      showToast(message, type)
    })

    // 一度表示したらDOM上のメッセージは不要
    this.element.innerHTML = ""
  }

  normalizeType(type) {
    const key = (type || "").toString()

    if (["notice", "success"].includes(key)) return "success"
    if (["alert", "error"].includes(key)) return "error"
    if (key === "warning") return "warning"
    return "info"
  }
}
