class Relationship < ApplicationRecord
  # リレーション
  has_many :gift_people, dependent: :restrict_with_error

  # バリデーション
  validates :name, presence: true, length: { maximum: 50 }
  validates :name, uniqueness: { case_sensitive: false }
  validates :position, presence: true, uniqueness: true

  # スコープ
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

  # 順序変更メソッド
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
