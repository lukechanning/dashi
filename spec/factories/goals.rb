FactoryBot.define do
  factory :goal do
    user
    title { "Get fit" }
    status { :active }
  end
end
