FactoryBot.define do
  factory :comment do
    body { "これは素晴らしいギフトですね！" }

    association :user
    association :gift_record

    trait :with_special_chars do
      body { "特殊文字を含むコメント: <script>alert('test')</script>" }
    end

    trait :short_comment do
      body { "短いコメント" }
    end
  end
end
