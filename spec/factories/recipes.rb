FactoryBot.define do
  factory :recipe do
    association :user
    sequence(:name) { |n| "Receta #{n}" }
    instructions { nil }
    publicly_shareable { false }
  end
end
