# frozen_string_literal: true

module ExerciseRoutines
  # Copies routine lines onto a new routine owned by +adopter+ (no public-catalog requirement on the source).
  class CopyRoutineForAdopter
    MAX_UNIQUIFY_ITERATIONS = 10_000

    def self.call(source:, adopter:, base_name:)
      name = uniquify_routine_name(adopter, base_name.to_s.strip)
      routine = ExerciseRoutine.new(user: adopter, name: name, publicly_shareable: false)
      CopyRoutineLines.call(target: routine, source: source)
      routine.save!
      routine
    end

    def self.uniquify_routine_name(adopter, base_name)
      raise ArgumentError, "base_name blank" if base_name.blank?

      norm = base_name.strip.downcase
      return base_name.strip unless adopter.exercise_routines.where(name_normalized: norm).exists?

      2.upto(2 + MAX_UNIQUIFY_ITERATIONS - 1) do |n|
        candidate = "#{base_name.strip} (#{n})"
        return candidate unless adopter.exercise_routines.where(name_normalized: candidate.strip.downcase).exists?
      end

      raise ArgumentError,
            "could not find a unique exercise routine name after #{MAX_UNIQUIFY_ITERATIONS} attempts"
    end
  end
end
