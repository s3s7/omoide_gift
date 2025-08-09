FactoryBot.define do
  factory :gift_record do
    sequence(:item_name) { |n| "誕生日プレゼント#{n}" }
    amount { 5000 }
    gift_at { Date.current - 1.week }
    memo { "とても喜んでもらえました" }
    is_public { true }

    association :user
    association :event
    association :gift_person
  end

  factory :gift_record_minimal, class: 'GiftRecord' do
    sequence(:item_name) { |n| "プレゼント#{n}" }
    gift_at { Date.current }

    association :user
    association :event
    association :gift_person
  end

  factory :private_gift_record, class: 'GiftRecord' do
    sequence(:item_name) { |n| "内緒のプレゼント#{n}" }
    gift_at { Date.current }
    is_public { false }

    association :user
    association :event
    association :gift_person
  end
end
