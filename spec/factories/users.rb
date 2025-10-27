FactoryBot.define do
  factory :user do
    name { "テストユーザー" }
    sequence(:email) { |n| "test#{n}@example.com" }
    password { "password123" }
    password_confirmation { "password123" }

    after(:build) do |user|
      user.skip_confirmation! if user.respond_to?(:skip_confirmation!)
    end

    trait :line_user do
      provider { "line" }
      sequence(:uid) { |n| "line_uid_#{n}" }
      sequence(:email) { |n| "line_user#{n}@example.com" }
    end
  end
end
