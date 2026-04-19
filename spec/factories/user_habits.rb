FactoryBot.define do
  factory :user_habit do
    user
    habit_category
    sequence(:name) { |n| "Habit #{n}" }
    name_normalized { name.strip.downcase }
    active { true }
    global_habit_template { nil }
    frequency_type { "daily" }
    frequency_params { {} }
    activation_date { nil }
    habit_metric_kind { "none" }
    daily_target { 1 }
  end
end
