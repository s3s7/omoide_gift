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

  # 性別推定（カラム追加なし）：関係性名から判定
  def self.ids_for_gender(gender)
    names = case gender.to_s
    when "male" then %w[父 兄 弟 祖父 息子 義父]
    when "female" then %w[母 姉 妹 祖母 娘 義母]
    else []
    end
    where(name: names).pluck(:id)
  end
end
