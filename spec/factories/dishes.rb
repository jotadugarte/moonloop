# frozen_string_literal: true

FactoryBot.define do
  factory :dish do
    association :user
    sequence(:name) { |n| "Plato #{n}" }
    instructions { nil }
    publicly_shareable { false }
    meal_type { "cena" }
  end
end
