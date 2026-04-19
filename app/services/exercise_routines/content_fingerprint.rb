# frozen_string_literal: true

require "digest"
require "json"

module ExerciseRoutines
  class ContentFingerprint
    def self.for_routine(routine)
      lines = routine.exercise_routine_lines.to_a.sort_by { |l| [ l.weekday, l.position, l.id || 0 ] }
      payload = lines.map { |l| [ l.weekday, l.position, l.label.to_s, l.notes.to_s ] }
      Digest::SHA256.hexdigest(JSON.generate(payload))
    end
  end
end
