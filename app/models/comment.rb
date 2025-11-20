class Comment < ApplicationRecord
  BODY_MAX_LENGTH = 100
  EXCERPT_DEFAULT_LIMIT = 50

  belongs_to :user
  belongs_to :gift_record

  validates :body, presence: { message: "を入力してください" },
                  length: { maximum: BODY_MAX_LENGTH, message: "は#{BODY_MAX_LENGTH}文字以内で入力してください" }

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

  def excerpt(limit = EXCERPT_DEFAULT_LIMIT)
    body.length > limit ? "#{body[0, limit]}..." : body
  end

  # Ransack ホワイトリスト 管理者画面で使用
  def self.ransackable_attributes(auth_object = nil)
    %w[
      body user_id gift_record_id created_at updated_at
    ]
  end

  def self.ransackable_associations(auth_object = nil)
    %w[
      user gift_record
    ]
  end
end
