# frozen_string_literal: true

module Habits
  class ProcessHabitReminderForUserHabit
    def self.call(user_habit:)
      new(user_habit: user_habit).call
    end

    def initialize(user_habit:)
      @user_habit = user_habit
    end

    def call
      return :inactive unless user_habit.active?
      return :reminder_disabled unless user_habit.reminder_enabled?

      user = user_habit.user
      timezone_name = user&.timezone
      return :missing_timezone if timezone_name.blank?

      tz = Time.find_zone(timezone_name)
      return :invalid_timezone unless tz

      local_date = tz.at(Time.current).to_date
      return :already_done if habit_done_on_local_date?(local_date)

      begin
        HabitReminderEvent.create!(user: user, user_habit: user_habit, local_date: local_date)
      rescue ActiveRecord::RecordNotUnique
        return :ok
      end

      # [REQ-HAB-013]
      HabitReminderMailer.notify(user: user, user_habit: user_habit).deliver_now if user_habit.reminder_email?

      :ok
    end

    private

    attr_reader :user_habit

    def habit_done_on_local_date?(local_date)
      completion = user_habit.habit_completions.find_by(completed_on: local_date)
      Habits::Streak.habit_day_done?(user_habit: user_habit, completion: completion)
    end
  end
end
