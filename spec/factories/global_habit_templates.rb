FactoryBot.define do
  factory :global_habit_template do
    sequence(:code) { |n| "template_code_#{n}" }
    active { true }
  end
end

