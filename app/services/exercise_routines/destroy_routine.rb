# frozen_string_literal: true

module ExerciseRoutines
  class DestroyRoutine
    def self.call(routine:)
      ApplicationRecord.transaction do
        routine.exercise_routine_assignments.delete_all
        routine.destroy!
      end
    end
  end
end
