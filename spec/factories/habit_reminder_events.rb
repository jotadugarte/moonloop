FactoryBot.define do
  factory :habit_reminder_event do
    user
    user_habit
    local_date { Date.new(2026, 4, 19) }
  end
end
