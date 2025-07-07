class GiftPerson < ApplicationRecord
  belongs_to :user
  belongs_to :gift_record
  belongs_to :relationship
end
