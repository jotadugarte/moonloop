# frozen_string_literal: true

module Habits
  # REQ-RPT-001: due vs done counts and fulfillment % over an inclusive local Date range.
  # Inactive habits: returns +nil+ when there is no +HabitCompletion+ in +range+; otherwise uses
  # +DueOnDate+ with +schedule_only: true+ so denominators match the habit schedule.
  class FulfillmentForPeriod
    Stats = Struct.new(:due_count, :done_count, :percentage, keyword_init: true)

    def self.call(user_habit:, range:, completions_by_date: nil)
      new(user_habit: user_habit, range: range, completions_by_date: completions_by_date).call
    end

    def initialize(user_habit:, range:, completions_by_date:)
      @user_habit = user_habit
      @range = range
      @completions_by_date = completions_by_date
    end

    def call
      validate_range!

      completions = @completions_by_date || load_completions_index
      return nil if omit_inactive?(completions)

      schedule_only = !@user_habit.active?
      due_count = 0
      done_count = 0

      (@range.begin..@range.end).each do |d|
        next unless DueOnDate.due_on?(@user_habit, d, schedule_only: schedule_only)

        due_count += 1
        done_count += 1 if completions[d]&.status == "done"
      end

      Stats.new(
        due_count: due_count,
        done_count: done_count,
        percentage: percentage_for(due_count, done_count)
      )
    end

    private

    def validate_range!
      raise ArgumentError, "range must be a Range of Date" unless @range.is_a?(Range)
      raise ArgumentError, "range endpoints must be Date" unless @range.begin.is_a?(Date) && @range.end.is_a?(Date)
      raise ArgumentError, "range start must be <= end" if @range.begin > @range.end
    end

    def load_completions_index
      @user_habit.habit_completions.where(completed_on: @range.begin..@range.end).index_by(&:completed_on)
    end

    # Empty +Hash+ means no rows in the supplied window; inactive habits then stay hidden (REQ-RPT-001 §5).
    def omit_inactive?(completions)
      !@user_habit.active? && completions.values.none?
    end

    def percentage_for(due_count, done_count)
      return nil if due_count.zero?

      ((100 * done_count.to_r) / due_count).round
    end
  end
end
