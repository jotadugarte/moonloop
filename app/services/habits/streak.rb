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
      0
    end
  end
end
