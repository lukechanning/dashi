FactoryBot.define do
  factory :note do
    user
    body { "Some notes here." }
    association :notable, factory: :goal
  end
end
