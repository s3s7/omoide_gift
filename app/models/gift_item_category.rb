class GiftItemCategory < ApplicationRecord
  # リレーション
  has_many :gift_records, dependent: :restrict_with_error

  # バリデーション
  validates :name, presence: true, length: { maximum: 20 }
  validates :name, uniqueness: { case_sensitive: false }
  validates :position, presence: true, uniqueness: true

  # スコープ（クエリの再利用性と可読性向上）
  scope :active, -> { where.not(name: [ nil, "" ]) }
  scope :ordered, -> { order(:position) }

  # インスタンスメソッド
  def display_name
    name.presence || "未設定"
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
      update!(position: 0)
      target.update!(position: current_position)
      update!(position: target_position)
    end
  end
end
