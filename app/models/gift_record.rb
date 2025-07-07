class GiftRecord < ApplicationRecord
  belongs_to :user
  belongs_to :event
  belongs_to :gift_person
end
