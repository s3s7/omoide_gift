class Relationship < ApplicationRecord
  include PositionMovable
  include DisplayNameable

  # リレーション
  has_many :gift_people, dependent: :restrict_with_error

  # バリデーション
  validates :name, presence: true, length: { maximum: 50 }
  validates :name, uniqueness: { case_sensitive: false }

  # スコープ
  scope :active, -> { where.not(name: [ nil, "" ]) }

end
