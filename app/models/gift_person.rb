class GiftPerson < ApplicationRecord
  belongs_to :user
  belongs_to :relationship
  has_many :gift_records, foreign_key: "gift_people_id", dependent: :destroy

  validates :name, presence: true, length: { minimum: 1 }
  validates :name, format: { with: /\A\S+.*\S*\z/, message: "空白のみは無効です" }
end
