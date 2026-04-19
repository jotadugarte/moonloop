# frozen_string_literal: true

module ExerciseRoutines
  # Copies ordered lines from +source+ onto +target+ (in-memory; caller saves +target+).
  class CopyRoutineLines
    def self.call(target:, source:)
      source.exercise_routine_lines.sort_by { |l| [ l.weekday, l.position ] }.each do |line|
        target.exercise_routine_lines.build(
          weekday: line.weekday,
          position: line.position,
          label: line.label,
          notes: line.notes
        )
      end
    end
  end
end
