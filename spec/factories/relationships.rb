FactoryBot.define do
  factory :relationship do
    sequence(:name) { |n| "家族#{n}" }
  end

  factory :friend_relationship, class: 'Relationship' do
    sequence(:name) { |n| "友人#{n}" }
  end

  factory :colleague_relationship, class: 'Relationship' do
    sequence(:name) { |n| "同僚#{n}" }
  end
end
