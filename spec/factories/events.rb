FactoryBot.define do
  factory :event do
    sequence(:name) { |n| "誕生日#{n}" }
  end

  factory :christmas_event, class: 'Event' do
    sequence(:name) { |n| "クリスマス#{n}" }
  end

  factory :anniversary_event, class: 'Event' do
    sequence(:name) { |n| "記念日#{n}" }
  end
end
