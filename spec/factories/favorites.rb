FactoryBot.define do
  factory :favorite do
    association :user
    association :gift_record
  end
end
