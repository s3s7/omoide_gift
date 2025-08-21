import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="gift-person-form"
export default class extends Controller {
  static targets = [
    "input",
    "avatarInput", 
    "avatarPreview", 
    "currentAvatar", 
    "resetButton", 
    "removeCheckbox",
    "memoField",
    "memoCounter"
  ]
  
  static values = {
    maxFileSize: { type: Number, default: 5242880 }, // 5MB in bytes
    allowedTypes: { type: Array, default: ["image/jpeg", "image/jpg", "image/png", "image/webp"] },
    focusColor: { type: String, default: "#FC913A" },
    blurColor: { type: String, default: "#e1e5e9" }
  }

  connect() {
    this.setupInputFocusHandling()
    this.setupMemoCounter()
  }

  disconnect() {
    // Cleanup if needed
  }

  // Input focus/blur handling for all form inputs
  setupInputFocusHandling() {
    this.inputTargets.forEach(input => {
      input.addEventListener('focus', this.handleInputFocus.bind(this))
      input.addEventListener('blur', this.handleInputBlur.bind(this))
    })
  }

  handleInputFocus(event) {
    event.target.style.borderColor = this.focusColorValue
  }

  handleInputBlur(event) {
    event.target.style.borderColor = this.blurColorValue
  }

  // Avatar file selection and preview
  avatarSelected(event) {
    const file = event.target.files[0]
    
    if (!file) {
      this.resetAvatarPreview()
      return
    }

    // Validate file size
    if (file.size > this.maxFileSizeValue) {
      this.showError('ファイルサイズは5MB以下にしてください。')
      this.clearAvatarInput()
      return
    }

    // Validate file type
    if (!this.allowedTypesValue.includes(file.type)) {
      this.showError('JPEG、PNG、WEBP形式のファイルのみアップロードできます。')
      this.clearAvatarInput()
      return
    }

    this.previewAvatar(file)
  }

  previewAvatar(file) {
    const reader = new FileReader()
    
    reader.onload = (e) => {
      // Show preview image
      if (this.hasAvatarPreviewTarget) {
        this.avatarPreviewTarget.src = e.target.result
        this.avatarPreviewTarget.style.display = 'block'
      }
      
      // Dim current avatar
      if (this.hasCurrentAvatarTarget) {
        this.currentAvatarTarget.style.opacity = '0.3'
      }
      
      // Show reset button
      if (this.hasResetButtonTarget) {
        this.resetButtonTarget.style.display = 'inline-block'
      }
      
      // Disable remove checkbox if present
      if (this.hasRemoveCheckboxTarget) {
        this.removeCheckboxTarget.checked = false
        this.removeCheckboxTarget.disabled = true
      }
    }
    
    reader.onerror = () => {
      this.showError('ファイルの読み込みに失敗しました。')
      this.clearAvatarInput()
    }
    
    reader.readAsDataURL(file)
  }

  resetAvatarPreview() {
    // Clear file input
    this.clearAvatarInput()
    
    // Hide preview
    if (this.hasAvatarPreviewTarget) {
      this.avatarPreviewTarget.src = ''
      this.avatarPreviewTarget.style.display = 'none'
    }
    
    // Restore current avatar opacity
    if (this.hasCurrentAvatarTarget) {
      this.currentAvatarTarget.style.opacity = '1'
    }
    
    // Hide reset button
    if (this.hasResetButtonTarget) {
      this.resetButtonTarget.style.display = 'none'
    }
    
    // Re-enable remove checkbox if present
    if (this.hasRemoveCheckboxTarget) {
      this.removeCheckboxTarget.disabled = false
    }
  }

  clearAvatarInput() {
    if (this.hasAvatarInputTarget) {
      this.avatarInputTarget.value = ''
    }
  }

  // Remove avatar checkbox handling
  removeAvatarToggled(event) {
    const isChecked = event.target.checked
    
    if (isChecked) {
      // Clear any file selection and preview
      this.clearAvatarInput()
      
      if (this.hasAvatarPreviewTarget) {
        this.avatarPreviewTarget.src = ''
        this.avatarPreviewTarget.style.display = 'none'
      }
      
      if (this.hasResetButtonTarget) {
        this.resetButtonTarget.style.display = 'none'
      }
      
      // Dim current avatar to show it will be removed
      if (this.hasCurrentAvatarTarget) {
        this.currentAvatarTarget.style.opacity = '0.3'
      }
    } else {
      // Restore current avatar opacity
      if (this.hasCurrentAvatarTarget) {
        this.currentAvatarTarget.style.opacity = '1'
      }
    }
  }

  // Memo field character counter
  setupMemoCounter() {
    if (!this.hasMemoFieldTarget) return
    
    // Create counter element if it doesn't exist
    if (!this.hasMemoCounterTarget) {
      this.createMemoCounter()
    }
    
    this.updateMemoCounter()
  }

  createMemoCounter() {
    const counterDiv = document.createElement('div')
    counterDiv.style.cssText = 'font-size: 11px; color: #999; text-align: right; margin-top: 4px;'
    counterDiv.setAttribute('data-gift-person-form-target', 'memoCounter')
    
    // Insert after the memo field
    this.memoFieldTarget.parentNode.appendChild(counterDiv)
  }

  memoInput() {
    this.updateMemoCounter()
  }

  updateMemoCounter() {
    if (!this.hasMemoFieldTarget || !this.hasMemoCounterTarget) return
    
    const currentLength = this.memoFieldTarget.value.length
    const maxLength = parseInt(this.memoFieldTarget.getAttribute('maxlength')) || 100
    
    this.memoCounterTarget.textContent = `${currentLength}/${maxLength}文字`
    
    // Update color based on usage
    let color = '#999'
    if (currentLength > maxLength * 0.9) {
      color = '#dc3545' // Red when near/over limit
    } else if (currentLength > maxLength * 0.8) {
      color = '#ffc107' // Yellow when getting close
    }
    
    this.memoCounterTarget.style.color = color
  }

  // Utility methods
  showError(message) {
    // Use browser alert for now, could be enhanced with better UI
    alert(message)
  }

  // Handle form submission validation if needed
  validateForm(event) {
    // Additional validation can be added here if needed
    return true
  }
}