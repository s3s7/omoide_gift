class GiftPerson < ApplicationRecord
  belongs_to :user
  belongs_to :relationship
  has_many :gift_records, foreign_key: "gift_people_id", dependent: :destroy
  has_many :reminds, dependent: :destroy

  validates :name, presence: true, length: { minimum: 1 }
  validates :name, format: { with: /\A\S+.*\S*\z/, message: "空白のみは無効です" }

  # 指定された日付時点での年齢を計算
  def age_at(reference_date = Date.current)
    return nil unless birthday.present?

    reference_date = reference_date.to_date
    birthday_date = birthday.to_date

    # 誕生日が参照日より未来の場合は0歳とする
    return 0 if birthday_date > reference_date

    # 基本的な年齢計算
    age = reference_date.year - birthday_date.year

    # その年の誕生日がまだ来ていない場合は1歳減らす
    if reference_date.month < birthday_date.month ||
      (reference_date.month == birthday_date.month && reference_date.day < birthday_date.day)
      age -= 1
    end

    age
  end

  # 指定された日付時点での年齢を日本語形式で表示
  def display_age_at(reference_date = Date.current)
    age = age_at(reference_date)
    return nil unless age

    case age
    when 0
      "0歳"
    else
      "#{age}歳"
    end
  end
end
