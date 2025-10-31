class GiftItemCategory < ApplicationRecord
  include PositionMovable
  include DisplayNameable

  NAME_MAX_LENGTH = 20

  # リレーション
  has_many :gift_records, dependent: :restrict_with_error

  # バリデーション
  validates :name, presence: true, length: { maximum: NAME_MAX_LENGTH }
  validates :name, uniqueness: { case_sensitive: false }

  # スコープ（クエリの再利用性と可読性向上）
  scope :active, -> { where.not(name: [ nil, "" ]) }
end
