class Event < ApplicationRecord
  # リレーション
  has_many :gift_records, dependent: :nullify

  # バリデーション
  validates :name, presence: true, length: { maximum: 100 }
  validates :name, uniqueness: { case_sensitive: false }

  # スコープ（クエリの再利用性と可読性向上）
  scope :active, -> { where.not(name: [ nil, "" ]) }
  scope :ordered, -> { order(:name) }
  scope :frequently_used, -> {
    joins(:gift_records)
      .group(:id)
      .order("COUNT(gift_records.id) DESC")
  }

  # インスタンスメソッド
  def display_name
    name.presence || "未設定"
  end

  # ギフト記録数を取得
  def gift_records_count
    gift_records.count
  end

  # クラスメソッド（よく使われるイベントの取得）
  def self.popular_events(limit = 5)
    frequently_used.limit(limit)
  end

end
