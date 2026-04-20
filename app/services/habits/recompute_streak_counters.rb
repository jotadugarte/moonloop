# frozen_string_literal: true

module Habits
  class RecomputeStreakCounters
    def self.call(user_habit:)
      new(user_habit: user_habit).call
    end

    def initialize(user_habit:)
      @user_habit = user_habit
    end

    def call
      return :not_supported unless @user_habit.respond_to?(:streak_counters_stale)

      zone = Time.find_zone!(@user_habit.user.timezone)
      today = zone.today

      current = ReportCurrentStreak.call(user_habit: @user_habit, as_of: today)
      longest = LongestStreak.call(user_habit: @user_habit, through_date: today)

      @user_habit.update!(
        current_streak_today: current,
        longest_streak_through_today: longest,
        streak_counters_as_of: today,
        streak_counters_stale: false
      )

      :ok
    end
  end
end
