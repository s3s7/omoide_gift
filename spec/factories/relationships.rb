FactoryBot.define do
  factory :relationship do
    sequence(:name) { |n| "家族#{n}" }
    sequence(:position) { |n| 40_000 + n }
  end

  factory :friend_relationship, class: 'Relationship' do
    sequence(:name) { |n| "友人#{n}" }
    sequence(:position) { |n| 50_000 + n }
  end

  factory :colleague_relationship, class: 'Relationship' do
    sequence(:name) { |n| "同僚#{n}" }
    sequence(:position) { |n| 60_000 + n }
  end
end
