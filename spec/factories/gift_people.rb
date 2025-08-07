FactoryBot.define do
  factory :gift_person do
    sequence(:name) { |n| "田中太郎#{n}" }
    birthday { Date.current - 30.years }
    likes { "コーヒー、読書" }
    dislikes { "辛い食べ物" }
    memo { "いつも笑顔で優しい人" }

    association :user
    association :relationship
  end

  factory :gift_person_with_minimal_data, class: 'GiftPerson' do
    sequence(:name) { |n| "最小データ#{n}" }

    association :user
    association :relationship
  end
end
