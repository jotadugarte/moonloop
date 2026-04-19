# frozen_string_literal: true

FactoryBot.define do
  factory :habit_completion do
    user_habit
    completed_on { Date.current }
    status { "done" }
    day_progress { 0 }
  end
end
