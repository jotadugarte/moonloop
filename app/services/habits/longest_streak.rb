# frozen_string_literal: true

module Habits
  # All-time longest run of consecutive *due* days each marked *done* (REQ-RPT-002, REQ-DAY-004).
  # *through_date* defaults to the user's local today. Open *today* does not break or extend a run
  # unless marked *done* (parity with Habits::Streak). Inactive habits use +schedule_only+ due checks.
  class LongestStreak
    def self.call(user_habit:, through_date: nil, completions_by_date: nil)
      new(user_habit: user_habit, through_date: through_date, completions_by_date: completions_by_date).call
    end

    def initialize(user_habit:, through_date:, completions_by_date:)
      @user_habit = user_habit
      @through_date = through_date
      @completions_by_date = completions_by_date
    end

    def call
      zone = Time.find_zone!(@user_habit.user.timezone)
      user_today = zone.today
      through = @through_date || user_today

      raise ArgumentError, "through_date must be a Date" unless through.is_a?(Date)
      raise ArgumentError, "through_date cannot be after the user's local today" if through > user_today

      lower = Streak.lower_bound_for(@user_habit)
      raise ArgumentError, "through_date cannot be before this habit's schedulable window" if through < lower

      span_days = (through - lower).to_i + 1
      if span_days > Streak::MAX_CALENDAR_DAY_STEPS
        raise ArgumentError,
              "longest-streak scan exceeded #{Streak::MAX_CALENDAR_DAY_STEPS} calendar days " \
              "(through=#{through}, lower=#{lower})"
      end

      completions = @completions_by_date || load_completions(lower, through)
      schedule_only = !@user_habit.active?

      current = 0
      best = 0

      (lower..through).each do |d|
        next unless DueOnDate.due_on?(@user_habit, d, schedule_only: schedule_only)

        comp = completions[d]
        done = comp&.status == "done"

        if d < user_today
          if done
            current += 1
            best = [ best, current ].max
          else
            current = 0
          end
        elsif done
          current += 1
          best = [ best, current ].max
        end
      end

      best
    end

    private

    def load_completions(lower, through)
      @user_habit.habit_completions.where(completed_on: lower..through).index_by(&:completed_on)
    end
  end
end
