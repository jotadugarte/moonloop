# frozen_string_literal: true

module Habits
  # Builds the same `user_habit_id => streak_count` map as Mi Día uses for streaks (REQ-DAY-004):
  # one range query for completions, then +Habits::Streak+ per habit. Results are memoized in +Rails.cache+
  # keyed by user, local date, and each due habit's current +updated_at+ (see +RecordCompletion+ / +ClearCompletion+ +touch+).
  #
  # Due-habit metadata (+sorted_due_habit_ids+, streak window lower bound, ordered ids for the SQL +IN+ clause)
  # is computed in a single pass over +@due_habits+ per request before the cache fetch.
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
      capture_due_habit_metadata!
      Rails.cache.fetch(prefetch_cache_key) { compute_streak_map }
    end

    private

    def ensure_due_habits_owned!
      foreign = @due_habits.any? { |uh| uh.user_id != @user.id }
      raise ArgumentError, "due_habits must belong to the given user" if foreign
    end

    def capture_due_habit_metadata!
      lower_bound, ordered_ids = due_habits_lower_bound_and_ordered_ids
      @streak_window_lower_bound = lower_bound
      @ordered_due_habit_ids = ordered_ids
      @sorted_due_habit_ids = ordered_ids.uniq.sort
    end

    def due_habits_lower_bound_and_ordered_ids
      lowers = []
      ordered = []
      @due_habits.each do |h|
        lowers << Streak.lower_bound_for(h)
        ordered << h.id
      end
      [ lowers.min, ordered ]
    end

    def prefetch_cache_key
      tuples = persisted_habit_version_tuples(@sorted_due_habit_ids)
      [ "habits/mi_day_streak/v1", @user.id, @local_date.iso8601, tuples ]
    end

    def persisted_habit_version_tuples(ids)
      tuples = UserHabit.where(user_id: @user.id, id: ids).pluck(:id, :updated_at).sort_by(&:first)
      ensure_all_habits_persisted!(ids, tuples)
      tuples
    end

    def ensure_all_habits_persisted!(expected_ids, tuples)
      return if tuples.size == expected_ids.size

      raise ArgumentError, "due_habits must reference persisted habits for this user"
    end

    def compute_streak_map
      by_habit = index_completions_by_habit_and_date(completion_rows_for_streak_window)
      streak_map_from_due_habits(by_habit)
    end

    def completion_rows_for_streak_window
      HabitCompletion
        .where(user_habit_id: @ordered_due_habit_ids, completed_on: @streak_window_lower_bound..@local_date)
        .select(:id, :user_habit_id, :completed_on, :status)
        .to_a
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
