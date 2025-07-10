class GiftPerson < ApplicationRecord
  belongs_to :user
  belongs_to :gift_record
  belongs_to :relationship

  validates :memo, presence: true, length: { maximum: 100 }
  validates :item_name, presence: true
  validates :amount, presence: true
  # validates :event, presence: true
  # validates :gift_people_id, presence: true

  validates :gift_at, presence: true


end
