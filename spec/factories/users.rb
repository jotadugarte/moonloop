FactoryBot.define do
  factory :user do
    sequence(:email) { |n| "user#{n}@example.com" }
    password { "Password123!" }
    date_of_birth { 30.years.ago.to_date }
    height_cm { 175 }
    timezone { "America/New_York" }
  end
end
