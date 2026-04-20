# frozen_string_literal: true

module Programs
  # [REQ-PHS-001] Copies a user's PhaseProgram segments into global phase plan rows (menus + routines).
  class ApplyBundleToUser
    class Error < StandardError
      attr_reader :key

      def initialize(key)
        @key = key
        super()
      end
    end

    def self.call(phase_program:, user:)
      unless phase_program.user_id == user.id
        raise Error.new(:wrong_owner)
      end

      ApplicationRecord.transaction do
        user.phase_assignments.delete_all
        user.exercise_routine_assignments.delete_all
        segments = phase_program.phase_program_assignments.order(:start_week, :id)
        segments.each do |segment|
          user.phase_assignments.create!(
            menu_id: segment.menu_id,
            start_week: segment.start_week,
            end_week: segment.end_week
          )
          user.exercise_routine_assignments.create!(
            exercise_routine_id: segment.exercise_routine_id,
            start_week: segment.start_week,
            end_week: segment.end_week
          )
        end
      end
    end
  end
end
