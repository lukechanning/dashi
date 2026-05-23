FactoryBot.define do
  factory :chain do
    user
    title { "Morning Routine" }
    description { nil }
    emoji { nil }
    completed_at { nil }

    trait :completed do
      completed_at { Time.current }
    end
  end
end
