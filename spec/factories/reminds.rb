FactoryBot.define do
  factory :remind do
    association :user
    association :gift_person
    notification_at { Date.current }
    notification_sent_at { 1.hour.from_now }
    is_sent { false }
  end
end
