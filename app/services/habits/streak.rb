# frozen_string_literal: true

module Habits
  # Current streak length (REQ-DAY-004) — expanded example-by-example in streak_spec.
  class Streak
    # Hard cap on backward day-steps (see docs/core/deterministic_coding_standards.md Rule 2).
    # Real walks are O(as_of − lower); this only guards pathological ranges or bugs.
    MAX_CALENDAR_DAY_STEPS = 100_000
    def self.call(user_habit:, as_of:, completions_by_date: nil)
      new(user_habit: user_habit, as_of: as_of, completions_by_date: completions_by_date).call
    end

    def self.lower_bound_for(user_habit)
      user_habit.activation_date.presence ||
        user_habit.created_at.in_time_zone(user_habit.user.timezone).to_date
    end

    # REQ-DAY-005 / REQ-RPT-001: same "fulfilled due day" predicate as walking streaks — shared with
    # +FulfillmentForPeriod+ and +LongestStreak+ so Informes matches Mi Día.
    def self.habit_day_done?(user_habit:, completion:)
      return false if completion.nil?
      return false unless completion.status == "done"
      return true if user_habit.habit_metric_kind == "none"

      completion.day_progress.to_i >= user_habit.daily_target.to_i
    end

    def initialize(user_habit:, as_of:, completions_by_date: nil)
      @user_habit = user_habit
      @as_of = as_of
      @completions_by_date = completions_by_date
    end

    def call
      raise ArgumentError, "as_of must be a Date" unless @as_of.is_a?(Date)

      user_today = Time.find_zone!(@user_habit.user.timezone).today
      raise ArgumentError, "as_of cannot be after the user's local today" if @as_of > user_today

      lower = lower_bound_date
      raise ArgumentError, "as_of cannot be before this habit's schedulable window" if @as_of < lower

      return 0 unless @user_habit.active?

      cursor = @as_of
      streak = 0
      steps = 0

      while cursor >= lower
        steps += 1
        if steps > MAX_CALENDAR_DAY_STEPS
          raise ArgumentError,
                "streak walk exceeded #{MAX_CALENDAR_DAY_STEPS} steps (as_of=#{ @as_of }, lower=#{ lower })"
        end

        unless DueOnDate.due_on?(@user_habit, cursor)
          cursor -= 1
          next
        end

        break if cursor > user_today

        if cursor == user_today
          comp = completion_on(cursor)
          streak += 1 if streak_day_done?(comp)
          cursor -= 1
          next
        end

        comp = completion_on(cursor)
        if streak_day_done?(comp)
          streak += 1
          cursor -= 1
        else
          break
        end
      end

      streak
    end

    private

    def streak_day_done?(comp)
      self.class.habit_day_done?(user_habit: @user_habit, completion: comp)
    end

    def completion_on(date)
      if @completions_by_date
        @completions_by_date[date]
      else
        @user_habit.habit_completions.find_by(completed_on: date)
      end
    end

    def lower_bound_date
      self.class.lower_bound_for(@user_habit)
    end
  end
end
