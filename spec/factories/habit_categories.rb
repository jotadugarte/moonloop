FactoryBot.define do
  factory :habit_category do
    user
    sequence(:name) { |n| "Category #{n}" }
    name_normalized { name.strip.downcase }
  end
end
