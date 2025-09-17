class Event < ApplicationRecord
  # リレーション
  has_many :gift_records, dependent: :nullify

  # バリデーション
  validates :name, presence: true, length: { maximum: 100 }
  validates :name, uniqueness: { case_sensitive: false }
  validates :position, presence: true, uniqueness: true

  # スコープ（クエリの再利用性と可読性向上）
  scope :active, -> { where.not(name: [ nil, "" ]) }
  scope :ordered, -> { order(:position) }
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

  # 順序変更メソッド
  def move_up!
    return if position == 1
    swap_positions!(position - 1)
  end

  def move_down!
    return if position == self.class.maximum(:position)
    swap_positions!(position + 1)
  end

  private

  def swap_positions!(target_position)
    target = self.class.find_by(position: target_position)
    return unless target

    self.class.transaction do
      current_position = position
      update!(position: 0) # 一時的に0に設定
      target.update!(position: current_position)
      update!(position: target_position)
    end
  end
end
