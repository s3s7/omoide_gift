class GiftPerson < ApplicationRecord
  belongs_to :user
  belongs_to :gift_record, optional: true  # gift_record_idは任意
  belongs_to :relationship

  validates :name, presence: true, length: { minimum: 1 }
  validates :name, format: { with: /\A\S+.*\S*\z/, message: "空白のみは無効です" }
end
