FactoryBot.define do
  factory :chain_item do
    chain
    sequence(:position) { |n| n - 1 }
    title { "Step one" }
    description { nil }
    emoji { nil }
    item_type { "todo" }
    todo_id { nil }
    project_id { nil }
    completed_at { nil }

    trait :todo_type do
      item_type { "todo" }
    end

    trait :project_type do
      item_type { "project" }
    end

    trait :activated_todo do
      item_type { "todo" }
      association :todo
    end

    trait :activated_project do
      item_type { "project" }
      association :project
    end

    trait :completed do
      completed_at { Time.current }
    end
  end
end
