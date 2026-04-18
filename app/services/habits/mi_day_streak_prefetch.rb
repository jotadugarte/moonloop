# frozen_string_literal: true

module Habits
  # Builds the same `user_habit_id => streak_count` map as Mi Día uses for streaks (REQ-DAY-004):
  # one range query for completions, then {Streak} per habit. Results are memoized in +Rails.cache+
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

      ensure_due_habits_owned!
      Rails.cache.fetch(prefetch_cache_key) { compute_streak_map }
    end

    private

    def ensure_due_habits_owned!
      foreign = @due_habits.any? { |uh| uh.user_id != @user.id }
      raise ArgumentError, "due_habits must belong to the given user" if foreign
    end

    def prefetch_cache_key
      ids = sorted_due_habit_ids
      tuples = persisted_habit_version_tuples(ids)
      [ "habits/mi_day_streak/v1", @user.id, @local_date.iso8601, tuples ]
    end

    def sorted_due_habit_ids
      @due_habits.map(&:id).uniq.sort
    end

    def persisted_habit_version_tuples(ids)
      tuples = UserHabit.where(user_id: @user.id, id: ids).pluck(:id, :updated_at).sort_by(&:first)
      if tuples.size != ids.size
        raise ArgumentError, "due_habits must reference persisted habits for this user"
      end
      tuples
    end

    def compute_streak_map
      by_habit = index_completions_by_habit_and_date(completion_rows_for_streak_window)
      streak_map_from_due_habits(by_habit)
    end

    def completion_rows_for_streak_window
      scope = HabitCompletion.where(
        user_habit_id: due_habit_ids,
        completed_on: streak_window_start_on..@local_date
      )
      scope.select(:id, :user_habit_id, :completed_on, :status).to_a
    end

    def due_habit_ids
      @due_habits.map(&:id)
    end

    def streak_window_start_on
      lowers = @due_habits.map { |h| Streak.lower_bound_for(h) }
      lowers.min
    end

    def index_completions_by_habit_and_date(rows)
      rows
        .group_by(&:user_habit_id)
        .transform_values { |r| r.index_by(&:completed_on) }
    end

    def streak_map_from_due_habits(by_habit)
      @due_habits.each_with_object({}) do |habit, acc|
        acc[habit.id] = streak_for_habit(habit, by_habit)
      end
    end

    def streak_for_habit(habit, by_habit)
      dates = by_habit[habit.id] || {}
      Streak.call(user_habit: habit, as_of: @local_date, completions_by_date: dates)
    end
  end
end
