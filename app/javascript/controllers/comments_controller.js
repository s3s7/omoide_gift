import { Controller } from "@hotwired/stimulus"
import { showToast } from "../utils"

export default class extends Controller {
  static targets = ["form", "list", "editModal", "editForm", "editBody"]

  connect() {
    // フォーム送信イベントをリッスン
    const form = document.getElementById('comment-form')
    if (form) {
      form.addEventListener('submit', this.handleSubmit.bind(this))
    }
  }

  editComment(event) {
    const commentId = event.currentTarget.dataset.commentId
    const commentElement = document.getElementById(`comment-${commentId}`)
    const bodyElement = commentElement.querySelector('.comment-body')
    const currentBody = bodyElement.textContent.trim()
    
    const modal = document.getElementById('edit-comment-modal')
    const form = document.getElementById('edit-comment-form')
    const bodyInput = document.getElementById('edit-comment-body')
    
    // フォームの設定
    form.action = `/gift_records/${window.location.pathname.split('/')[2]}/comments/${commentId}`
    bodyInput.value = currentBody
    
    // モーダル表示
    modal.classList.remove('hidden')
    modal.classList.add('flex')
    bodyInput.focus()
    
    // フォーム送信処理
    form.onsubmit = (e) => {
      e.preventDefault()
      this.updateComment(commentId, bodyInput.value, bodyElement)
    }
  }

  deleteComment(event) {
    const commentId = event.currentTarget.dataset.commentId
    
    if (!confirm('このコメントを削除しますか？')) {
      return
    }
    
    const commentElement = document.getElementById(`comment-${commentId}`)
    const giftRecordId = window.location.pathname.split('/')[2]
    
    fetch(`/gift_records/${giftRecordId}/comments/${commentId}`, {
      method: 'DELETE',
      headers: {
        'Accept': 'application/json',
        'X-Requested-With': 'XMLHttpRequest',
        'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').getAttribute('content')
      }
    })
    .then(response => response.json())
    .then(data => {
      if (data.success) {
        commentElement.remove()
        this.updateCommentsCount(-1)
        showToast('コメントを削除しました', 'success')
        
        // コメントが0になったら空メッセージを表示
        const commentsList = document.getElementById('comments-list')
        if (commentsList.children.length === 0) {
          commentsList.innerHTML = `
            <div class="text-center py-8 text-gray-500">
              <i class="fas fa-comment-dots text-3xl mb-3"></i>
              <p class="text-sm">まだコメントがありません</p>
              <p class="text-xs mt-1">コメントを投稿して盛り上げよう！</p>
            </div>
          `
        }
      } else {
        showToast('削除に失敗しました', 'error')
      }
    })
    .catch(() => {
      showToast('通信エラーが発生しました', 'error')
    })
  }

  closeEditModal() {
    const modal = document.getElementById('edit-comment-modal')
    modal.classList.add('hidden')
    modal.classList.remove('flex')
  }

  updateComment(commentId, newBody, bodyElement) {
    const giftRecordId = window.location.pathname.split('/')[2]
    const formData = new FormData()
    formData.append('comment[body]', newBody)
    formData.append('_method', 'PATCH')
    formData.append('authenticity_token', document.querySelector('meta[name="csrf-token"]').getAttribute('content'))
    
    fetch(`/gift_records/${giftRecordId}/comments/${commentId}`, {
      method: 'POST',
      body: formData,
      headers: {
        'Accept': 'application/json',
        'X-Requested-With': 'XMLHttpRequest'
      }
    })
    .then(response => response.json())
    .then(data => {
      if (data.success) {
        bodyElement.textContent = data.comment.body
        this.closeEditModal()
        showToast('コメントを更新しました', 'success')
      } else {
        showToast('更新に失敗しました: ' + data.errors.join(', '), 'error')
      }
    })
    .catch(() => {
      showToast('通信エラーが発生しました', 'error')
    })
  }

  handleSubmit(event) {
    event.preventDefault()
    
    const form = event.target
    const formData = new FormData(form)
    const submitBtn = form.querySelector('#comment-submit-btn')

    this.hideInlineError()
    
    // ボタンを無効化
    submitBtn.disabled = true
    submitBtn.textContent = '投稿中...'
    
    fetch(form.action, {
      method: 'POST',
      body: formData,
      headers: {
        'Accept': 'application/json',
        'X-Requested-With': 'XMLHttpRequest'
      }
    })
    .then(response => response.json())
    .then(data => {
      if (data.success) {
        // コメント追加成功
        this.addCommentToList(data.comment)
        form.reset()
        this.updateCommentsCount(1)
        this.hideInlineError()
        showToast('コメントを投稿しました', 'success')
      } else {
        // エラー表示
        const errorMessage = this.buildErrorMessage(data.errors)
        showToast(errorMessage, 'error')
      }
    })
    .catch(() => {
      const errorMessage = 'コメントの投稿に失敗しました: 通信エラーが発生しました'
      showToast('通信エラーが発生しました', 'error')
    })
    .finally(() => {
      // ボタンを有効化
      submitBtn.disabled = false
      submitBtn.textContent = 'コメントを投稿'
    })
  }

  addCommentToList(comment) {
    const commentsList = document.getElementById('comments-list')
    const emptyMessage = commentsList.querySelector('.text-center')
    
    // 空メッセージを削除
    if (emptyMessage) {
      emptyMessage.remove()
    }
    
    // 新しいコメントHTML
    const commentHTML = `
      <div class="comment-item bg-white border border-gray-200 rounded-lg p-4" id="comment-${comment.id}">
        <div class="flex justify-between items-start mb-2">
          <div class="flex items-center">
            <div class="flex-shrink-0">
              <div class="w-8 h-8 bg-blue-100 rounded-full flex items-center justify-center">
                <i class="fas fa-user text-blue-600 text-sm"></i>
              </div>
            </div>
            <div class="ml-3">
              <p class="text-sm font-medium text-gray-900">${comment.user_name}</p>
              <p class="text-xs text-gray-500">${comment.created_at}</p>
            </div>
          </div>
          ${comment.can_edit ? `
            <div class="flex space-x-2">
              <button type="button" 
                      class="text-gray-400 hover:text-blue-600 text-sm"
                      data-action="click->comments#editComment"
                      data-comment-id="${comment.id}"
                      title="編集">
                <i class="fas fa-edit"></i>
              </button>
              <button type="button" 
                      class="text-gray-400 hover:text-red-600 text-sm"
                      data-action="click->comments#deleteComment"
                      data-comment-id="${comment.id}"
                      title="削除">
                <i class="fas fa-trash"></i>
              </button>
            </div>
          ` : ''}
        </div>
        <div class="comment-body text-sm text-gray-700 whitespace-pre-line pl-11">${this.escapeHtml(comment.body)}</div>
      </div>
    `
    
    // 最後に追加（oldest_firstなので）
    commentsList.insertAdjacentHTML('beforeend', commentHTML)
  }

  updateCommentsCount(change) {
    const countElement = document.querySelector('#comments-section h2 span')
    if (countElement) {
      const currentCount = parseInt(countElement.textContent.match(/\d+/)[0])
      const newCount = currentCount + change
      countElement.textContent = `(${newCount}件)`
    }
  }

  escapeHtml(text) {
    const div = document.createElement('div')
    div.textContent = text
    return div.innerHTML
  }

  showInlineError(message) {
    const errorElement = document.getElementById('comment-error-message')
    if (!errorElement) return
    errorElement.textContent = message
    errorElement.classList.remove('hidden')
  }

  hideInlineError() {
    const errorElement = document.getElementById('comment-error-message')
    if (!errorElement) return
    errorElement.textContent = ''
    errorElement.classList.add('hidden')
  }

  buildErrorMessage(errors) {
    if (errors && errors.length > 0) {
      return `コメントの投稿に失敗しました: ${errors.join(', ')}`
    }
    return 'コメントの投稿に失敗しました'
  }
}
