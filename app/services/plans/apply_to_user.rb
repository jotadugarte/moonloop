# frozen_string_literal: true

module Plans
  # [REQ-PHS-001] Copies a user's Plan assignments into global phase plan rows (menus + routines).
  class ApplyToUser
    class Error < StandardError
      attr_reader :key

      def initialize(key)
        @key = key
        super()
      end
    end

    def self.call(plan:, user:, phase_one_starts_on: nil)
      raise Error.new(:wrong_owner) unless plan.user_id == user.id

      anchor = resolve_anchor!(user: user, phase_one_starts_on: phase_one_starts_on)

      ApplicationRecord.transaction do
        user.update!(phase_one_starts_on: anchor) if user.phase_one_starts_on != anchor

        user.phase_assignments.delete_all
        user.exercise_routine_assignments.delete_all

        plan.plan_assignments.order(:start_week, :id).each do |row|
          user.phase_assignments.create!(menu_id: row.menu_id, start_week: row.start_week, end_week: row.end_week)
          user.exercise_routine_assignments.create!(
            exercise_routine_id: row.exercise_routine_id,
            start_week: row.start_week,
            end_week: row.end_week
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

