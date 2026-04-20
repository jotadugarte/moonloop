# frozen_string_literal: true

require "digest"
require "json"

module Programs
  class ContentFingerprint
    def self.for_program(program)
      segs = program.phase_program_assignments.includes(:menu, :exercise_routine).to_a.sort_by { |s| [ s.start_week, s.id || 0 ] }
      payload = segs.map do |s|
        [
          s.start_week,
          s.end_week,
          Menus::ContentFingerprint.for_menu(s.menu),
          ExerciseRoutines::ContentFingerprint.for_routine(s.exercise_routine)
        ]
      end
      Digest::SHA256.hexdigest(JSON.generate(payload))
    end
  end
end
