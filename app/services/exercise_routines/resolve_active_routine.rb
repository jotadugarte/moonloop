# frozen_string_literal: true

module ExerciseRoutines
  class ResolveActiveRoutine
    def self.call(user:, week_index:)
      new(user: user, week_index: week_index).exercise_routine
    end

    def initialize(user:, week_index:)
      @user = user
      @week_index = week_index
    end

    def exercise_routine
      return nil if @week_index.blank?

      assignment = @user.exercise_routine_assignments
        .includes(:exercise_routine)
        .order(:start_week)
        .find_by("? BETWEEN start_week AND end_week", @week_index)

      assignment&.exercise_routine
    end
  end
end
