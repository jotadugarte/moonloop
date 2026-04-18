# frozen_string_literal: true

module Habits
  # Builds the same `user_habit_id => streak_count` map as {MyDayController}'s streak helpers (REQ-DAY-004),
  # using one range query for completions then {Streak} per habit. Result is memoized in +Rails.cache+
  # keyed by user, local date, and each due habit's current +updated_at+ (see +RecordCompletion+ / +ClearCompletion+ +touch+).
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

      Rails.cache.fetch(prefetch_cache_key) { compute_streak_map }
    end

    private

    def prefetch_cache_key
      ids = @due_habits.map(&:id).uniq.sort
      tuples = UserHabit.where(user_id: @user.id, id: ids).pluck(:id, :updated_at).sort_by(&:first)
      raise ArgumentError, "due_habits must reference persisted habits for this user" if tuples.size != ids.size

      [ "habits/mi_day_streak/v1", @user.id, @local_date.iso8601, tuples ]
    end

    def compute_streak_map
      lowers = @due_habits.map { |h| Streak.lower_bound_for(h) }
      from = lowers.min
      habit_ids = @due_habits.map(&:id)

      rows = HabitCompletion
        .where(user_habit_id: habit_ids, completed_on: from..@local_date)
        .select(:id, :user_habit_id, :completed_on, :status)
        .to_a

      by_habit = rows
        .group_by(&:user_habit_id)
        .transform_values { |r| r.index_by(&:completed_on) }

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
