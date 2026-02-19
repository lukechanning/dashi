FactoryBot.define do
  factory :todo do
    user
    title { "Run 5k" }
    due_date { Date.current }

    trait :with_project do
      project
    end

    trait :completed do
      completed_at { Time.current }
    end

    trait :overdue do
      due_date { 2.days.ago.to_date }
    end
  end
end
