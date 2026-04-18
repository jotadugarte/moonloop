# frozen_string_literal: true

module Habits
  # Removes a completion row (pending state) per REQ-DAY-002 / REQ-DAY-003.
  class ClearCompletion
    def self.call(user:, habit_completion:)
      new(user: user, habit_completion: habit_completion).call
    end

    def initialize(user:, habit_completion:)
      @user = user
      @habit_completion = habit_completion
    end

    def call
      habit = @habit_completion.user_habit
      return :not_owner unless habit.user_id == @user.id
      return :inactive unless habit.active?

      @habit_completion.destroy!
      habit.touch

      :ok
    end
  end
end
