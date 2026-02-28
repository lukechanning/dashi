FactoryBot.define do
  factory :habit do
    user
    title { "Walk the dog" }
    frequency { :daily }
    start_date { Date.current }

    trait :weekdays do
      frequency { :weekdays }
    end

    trait :custom do
      frequency { :custom }
      days_of_week { "1,3,5" }
    end

    trait :paused do
      active { false }
    end

    trait :with_project do
      project
    end
  end
end
