class Relationship < ApplicationRecord
  # リレーション
  has_many :gift_people, dependent: :restrict_with_error

  # バリデーション
  validates :name, presence: true, length: { maximum: 50 }
  validates :name, uniqueness: { case_sensitive: false }

  # スコープ（クエリの再利用性と可読性向上）
  scope :active, -> { where.not(name: [ nil, "" ]) }
  scope :ordered, -> { order(:name) }

  # インスタンスメソッド
  def display_name
    name.presence || "未設定"
  end
end
