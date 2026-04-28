FactoryBot.define do
  factory :menu_entry do
    association :menu
    association :dish
    weekday { 0 }
    meal_type { "desayuno" }
    freeform_text { nil }
  end
end
