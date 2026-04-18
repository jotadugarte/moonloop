# frozen_string_literal: true

module Habits
  # Builds the same `user_habit_id => streak_count` map as {MyDayController}'s streak helpers (REQ-DAY-004),
  # using one range query for completions then {Streak} per habit.
  class MiDayStreakPrefetch
    def self.call(user:, due_habits:, local_date:)
      new(user: user, due_habits: due_habits, local_date: local_date).call
    end

    def initialize(user:, due_habits:, local_date:)
      @user = user
      @due_habits = due_habits
      @local_date = local_date
    end

    def call
      return {} if @due_habits.empty?

      if @due_habits.any? { |uh| uh.user_id != @user.id }
        raise ArgumentError, "due_habits must belong to the given user"
      end

      lowers = @due_habits.map { |h| Streak.lower_bound_for(h) }
      from = lowers.min
      habit_ids = @due_habits.map(&:id)

      by_habit = HabitCompletion
        .where(user_habit_id: habit_ids, completed_on: from..@local_date)
        .group_by(&:user_habit_id)
        .transform_values { |rows| rows.index_by(&:completed_on) }

      @due_habits.each_with_object({}) do |habit, acc|
        acc[habit.id] = Streak.call(
          user_habit: habit,
          as_of: @local_date,
          completions_by_date: by_habit[habit.id] || {}
        )
      end
    end
  end
end
