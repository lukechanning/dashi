FactoryBot.define do
  factory :project do
    user
    title { "Run 3x per week" }
    status { :active }

    trait :with_goal do
      goal
    end
  end
end
