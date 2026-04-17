# frozen_string_literal: true

module ExerciseRoutines
  # REQ-EXR-005: append a new range after the last assigned week, same routine and
  # length as the assignment that ends at the current maximum end_week.
  class RepeatLastAssignment
    def self.call(user:)
      new(user: user).call
    end

    def initialize(user:)
      @user = user
    end

    def call
      last = @user.exercise_routine_assignments.order(end_week: :desc, start_week: :desc).first
      return nil if last.nil?

      max_end = @user.exercise_routine_assignments.maximum(:end_week)
      span = last.end_week - last.start_week + 1
      new_start = max_end + 1
      new_end = new_start + span - 1

      @user.exercise_routine_assignments.create!(
        exercise_routine_id: last.exercise_routine_id,
        start_week: new_start,
        end_week: new_end
      )
    end
  end
end
