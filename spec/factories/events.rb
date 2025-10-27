FactoryBot.define do
  factory :event do
    sequence(:name) { |n| "誕生日#{n}" }
    sequence(:position) { |n| 10_000 + n }
  end

  factory :christmas_event, class: 'Event' do
    sequence(:name) { |n| "クリスマス#{n}" }
    sequence(:position) { |n| 20_000 + n }
  end

  factory :anniversary_event, class: 'Event' do
    sequence(:name) { |n| "記念日#{n}" }
    sequence(:position) { |n| 30_000 + n }
  end
end
