class GiftRecord < ApplicationRecord
  belongs_to :user
  belongs_to :event
  belongs_to :gift_people, class_name: 'GiftPerson'
end
