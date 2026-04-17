# frozen_string_literal: true

module Habits
  # Current streak length (REQ-DAY-004) — expanded example-by-example in streak_spec.
  class Streak
    def self.call(user_habit:, as_of:)
      new(user_habit: user_habit, as_of: as_of).call
    end

    def initialize(user_habit:, as_of:)
      @user_habit = user_habit
      @as_of = as_of
    end

    def call
      user_today = Time.find_zone!(@user_habit.user.timezone).today
      raise ArgumentError, "as_of cannot be after the user's local today" if @as_of > user_today

      return 0 unless @user_habit.active?

      cursor = @as_of
      streak = 0
      lower = lower_bound_date

      while cursor >= lower
        unless DueOnDate.due_on?(@user_habit, cursor)
          cursor -= 1
          next
        end

        break if cursor > user_today

        if cursor == user_today
          comp = completion_on(cursor)
          streak += 1 if comp&.status == "done"
          cursor -= 1
          next
        end

        comp = completion_on(cursor)
        if comp&.status == "done"
          streak += 1
          cursor -= 1
        else
          break
        end
      end

      streak
    end

    private

    def completion_on(date)
      @user_habit.habit_completions.find_by(completed_on: date)
    end

    def lower_bound_date
      @user_habit.activation_date.presence || @user_habit.created_at.in_time_zone(@user_habit.user.timezone).to_date
    end
  end
end
