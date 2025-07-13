class GiftPerson < ApplicationRecord
  belongs_to :user
  has_many :gift_records, dependent: :destroy
  belongs_to :relationship, optional: true

  validates :name, presence: true
end
