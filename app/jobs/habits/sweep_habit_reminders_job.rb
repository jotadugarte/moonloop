# frozen_string_literal: true

module Habits
  class SweepHabitRemindersJob < ApplicationJob
    queue_as :default

    def perform
      UserHabit.includes(:user)
        .where(active: true, reminder_enabled: true)
        .where.not(reminder_time_of_day: [ nil, "" ])
        .find_each do |habit|
          next unless habit_due_for_reminder_slot?(habit)

          Habits::ProcessHabitReminderForUserHabit.call(user_habit: habit)
        end
    end

    private

    def habit_due_for_reminder_slot?(habit)
      timezone_name = habit.user&.timezone
      return false if timezone_name.blank?

      tz = ActiveSupport::TimeZone[timezone_name]
      return false unless tz

      now_local = tz.at(Time.current)
      now_local.strftime("%H:%M") == habit.reminder_time_of_day
    end
  end
end
