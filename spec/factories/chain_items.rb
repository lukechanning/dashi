FactoryBot.define do
  factory :chain_item do
    chain
    sequence(:position) { |n| n - 1 }
    title { "Step one" }
    description { nil }
    todo_id { nil }
    completed_at { nil }

    trait :activated do
      association :todo
    end

    trait :completed do
      completed_at { Time.current }
    end
  end
end
