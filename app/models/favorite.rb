class Favorite < ApplicationRecord
  belongs_to :user
  belongs_to :gift_record

  # データベースレベルのユニーク制約と合わせてRailsレベルでもバリデーション
  validates :user_id, uniqueness: { scope: :gift_record_id, message: "このギフト記録は既にお気に入りに追加されています" }

  # バリデーション
  validates :user_id, presence: true
  validates :gift_record_id, presence: true

  # スコープ
  scope :recent, -> { order(created_at: :desc) }
  scope :for_user, ->(user) { where(user: user) }
  scope :with_public_records, -> { joins(:gift_record).where(gift_records: { is_public: true }) }

  # カスタムバリデーション：公開されているギフト記録、または自分のギフト記録のみお気に入りに追加可能
  validate :gift_record_is_accessible

  # クラスメソッド
  def self.favorited_by_user?(user, gift_record)
    exists?(user: user, gift_record: gift_record)
  end

  def self.toggle_favorite(user, gift_record)
    return { action: :failed, success: false, error: "ユーザーが無効です" } unless user.present?
    return { action: :failed, success: false, error: "ギフト記録が無効です" } unless gift_record.present?

    favorite = find_by(user: user, gift_record: gift_record)

    if favorite
      if favorite.destroy
        { action: :removed, success: true, favorited: false }
      else
        { action: :failed, success: false, errors: favorite.errors }
      end
    else
      favorite = new(user: user, gift_record: gift_record)
      if favorite.save
        { action: :added, success: true, favorited: true, favorite: favorite }
      else
        { action: :failed, success: false, errors: favorite.errors }
      end
    end
  rescue ActiveRecord::RecordNotUnique
    # データベースレベルのユニーク制約違反の場合
    { action: :failed, success: false, error: "このギフト記録は既にお気に入りに追加されています" }
  end

  def self.favorites_count_for_gift_record(gift_record)
    where(gift_record: gift_record).count
  end

  private

  def gift_record_is_accessible
    return unless user.present? && gift_record.present?

    # 自分のギフト記録の場合は常にOK
    return if gift_record.user_id == user.id

    # 他人のギフト記録の場合は公開されている必要がある
    unless gift_record.is_public?
      errors.add(:gift_record, "非公開のギフト記録はお気に入りに追加できません")
    end
  end
end
