FactoryBot.define do
  factory :global_habit_template do
    sequence(:code) { |n| "template_code_#{n}" }
    active { true }
    suggested_habit_metric_kind { "none" }
    suggested_daily_target { 1 }
  end
end
