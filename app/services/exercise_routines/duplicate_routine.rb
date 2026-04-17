# frozen_string_literal: true

module ExerciseRoutines
  class DuplicateRoutine
    def self.call(source:, new_name: nil)
      base_name = new_name.to_s.strip.presence || I18n.t("exercise_routines.duplicate.default_name", name: source.name)
      unique_name = DuplicateRoutine.uniquify(source.user, base_name)

      ApplicationRecord.transaction do
        duplicate = ExerciseRoutine.new(user: source.user, name: unique_name)
        source.exercise_routine_lines.sort_by { |l| [ l.weekday, l.position ] }.each do |line|
          duplicate.exercise_routine_lines.build(
            weekday: line.weekday,
            position: line.position,
            label: line.label,
            notes: line.notes
          )
        end
        duplicate.save!
        duplicate
      end
    end

    def self.uniquify(user, base_name)
      return base_name unless DuplicateRoutine.name_taken?(user, base_name)

      n = 2
      loop do
        candidate = "#{base_name} (#{n})"
        return candidate unless DuplicateRoutine.name_taken?(user, candidate)
        n += 1
      end
    end

    def self.name_taken?(user, name)
      normalized = name.to_s.strip.downcase
      user.exercise_routines.where(name_normalized: normalized).exists?
    end
  end
end
