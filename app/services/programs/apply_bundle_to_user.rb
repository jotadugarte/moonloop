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

    def self.call(phase_program:, user:, phase_one_starts_on: nil)
      unless phase_program.user_id == user.id
        raise Error.new(:wrong_owner)
      end
      anchor = resolve_anchor!(user: user, phase_one_starts_on: phase_one_starts_on)

      ApplicationRecord.transaction do
        user.update!(phase_one_starts_on: anchor) if user.phase_one_starts_on != anchor
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

    def self.resolve_anchor!(user:, phase_one_starts_on:)
      return user.phase_one_starts_on if user.phase_one_starts_on.present?
      raise Error.new(:anchor_required) unless phase_one_starts_on.is_a?(Date)

      phase_one_starts_on
    end
  end
end
