FactoryBot.define do
  factory :menu_entry do
    association :menu
    association :recipe
    weekday { 0 }
    meal_type { "desayuno" }
    freeform_text { nil }
  end
end

