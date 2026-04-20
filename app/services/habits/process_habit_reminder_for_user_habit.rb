# frozen_string_literal: true

module Habits
  class ProcessHabitReminderForUserHabit
    def self.call(user_habit:)
      new(user_habit: user_habit).call
    end

    def initialize(user_habit:)
      @user_habit = user_habit
    end

    def call
      # Step 6 only wires orchestration. Delivery + idempotency is covered in later steps.
      true
    end

    private

    attr_reader :user_habit
  end
end

