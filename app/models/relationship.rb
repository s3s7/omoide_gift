class Relationship < ApplicationRecord
  include PositionMovable
  include DisplayNameable

  NAME_MAX_LENGTH = 50

  # リレーション
  has_many :gift_people, dependent: :restrict_with_error

  # バリデーション
  validates :name, presence: true, length: { maximum: NAME_MAX_LENGTH }
  validates :name, uniqueness: { case_sensitive: false }

  # スコープ
  scope :active, -> { where.not(name: [ nil, "" ]) }
end
