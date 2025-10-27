class Event < ApplicationRecord
  include PositionMovable
  include DisplayNameable

  NAME_MAX_LENGTH = 100
  POPULAR_EVENTS_DEFAULT_LIMIT = 5

  # リレーション
  has_many :gift_records, dependent: :nullify

  # バリデーション
  validates :name, presence: true, length: { maximum: NAME_MAX_LENGTH }
  validates :name, uniqueness: { case_sensitive: false }

  # スコープ（クエリの再利用性と可読性向上）
  scope :active, -> { where.not(name: [ nil, "" ]) }
  scope :frequently_used, -> {
    joins(:gift_records)
      .group(:id)
      .order("COUNT(gift_records.id) DESC")
  }

  # ギフト記録数を取得
  def gift_records_count
    gift_records.count
  end

  # クラスメソッド（よく使われるイベントの取得）
  def self.popular_events(limit = POPULAR_EVENTS_DEFAULT_LIMIT)
    frequently_used.limit(limit)
  end

end
