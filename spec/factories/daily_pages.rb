FactoryBot.define do
  factory :daily_page do
    user
    date { Date.current }
  end
end
