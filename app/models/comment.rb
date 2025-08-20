class Comment < ApplicationRecord
  belongs_to :user
  belongs_to :gift_record

  validates :body, presence: { message: "を入力してください" },
                  length: { maximum: 100, message: "は100文字以内で入力してください" }

  scope :recent, -> { order(created_at: :desc) }
  scope :oldest_first, -> { order(created_at: :asc) }

  def can_edit_or_delete?(current_user)
    user == current_user
  end

  def display_created_at
    if created_at.today?
      I18n.l(created_at, format: :time_only)
    else
      I18n.l(created_at, format: :short)
    end
  end

  def excerpt(limit = 50)
    body.length > limit ? "#{body[0, limit]}..." : body
  end
end
