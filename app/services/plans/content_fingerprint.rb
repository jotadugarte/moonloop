# frozen_string_literal: true

require "digest"
require "json"

module Plans
  class ContentFingerprint
    def self.for_plan(plan)
      rows = plan.plan_assignments.includes(:menu, :exercise_routine).to_a.sort_by { |r| [ r.start_week, r.id || 0 ] }
      payload = rows.map do |r|
        [
          r.start_week,
          r.end_week,
          Menus::ContentFingerprint.for_menu(r.menu),
          ExerciseRoutines::ContentFingerprint.for_routine(r.exercise_routine)
        ]
      end
      Digest::SHA256.hexdigest(JSON.generate(payload))
    end
  end
end
