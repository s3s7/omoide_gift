FactoryBot.define do
  factory :user do
    name { "テストユーザー" }
    sequence(:email) { |n| "test#{n}@example.com" }
    password { "password123" }
    password_confirmation { "password123" }

    trait :line_user do
      provider { "line" }
      sequence(:uid) { |n| "line_uid_#{n}" }
      email { nil }
    end
  end
end
