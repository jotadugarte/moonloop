# frozen_string_literal: true

module Habits
  class RecomputeStreakCountersJob < ApplicationJob
    queue_as :default

    # [REQ-RPT-002]
    def perform(user_habit_id:)
      habit = UserHabit.find_by(id: user_habit_id)
      return unless habit

      Habits::RecomputeStreakCounters.call(user_habit: habit)
    end
  end
end
