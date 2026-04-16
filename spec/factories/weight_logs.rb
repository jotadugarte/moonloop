FactoryBot.define do
  factory :weight_log do
    user
    weight_kg { 70.0 }
    height_cm { 175 }
    bmi { 22.86 }
  end
end
