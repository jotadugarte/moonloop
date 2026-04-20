# frozen_string_literal: true

module Habits
  # Removes a completion row (pending state) per REQ-DAY-002 / REQ-DAY-003.
  class ClearCompletion
    def self.call(user:, habit_completion:)
      new(user: user, habit_completion: habit_completion).call
    end

    def initialize(user:, habit_completion:)
      @user = user
      @habit_completion = habit_completion
    end

    def call
      habit = @habit_completion.user_habit
      return :not_owner unless habit.user_id == @user.id
      return :inactive unless habit.active?

      @habit_completion.destroy!
      # Busts +Habits::MiDayStreakPrefetch+ cache keys (see +UserHabit#cache_key_with_version+).
      habit.touch

      mark_streak_counters_stale_if_retroactive!(habit)
      recompute_streak_counters_if_today!(habit)

      :ok
    end

    private

    def recompute_streak_counters_if_today!(habit)
      today = Time.find_zone!(@user.timezone).today
      return unless @habit_completion.completed_on == today

      Habits::RecomputeStreakCounters.call(user_habit: habit)
    end

    def mark_streak_counters_stale_if_retroactive!(habit)
      today = Time.find_zone!(@user.timezone).today
      return unless @habit_completion.completed_on < today

      habit.update!(streak_counters_stale: true)
    end
  end
end
