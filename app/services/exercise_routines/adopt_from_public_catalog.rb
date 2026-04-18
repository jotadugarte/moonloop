# frozen_string_literal: true

module ExerciseRoutines
  class AdoptFromPublicCatalog
    class Error < StandardError
      attr_reader :key

      def initialize(key)
        @key = key
        super()
      end
    end

    def self.call(adopter:, source:, chosen_name:)
      raise Error.new(:not_public) unless source.publicly_shareable?
      raise Error.new(:cannot_adopt_own) if source.user_id == adopter.id
      if adopter.exercise_routines.where(source_exercise_routine_id: source.id).exists?
        raise Error.new(:already_adopted)
      end

      name = chosen_name.to_s.strip
      raise Error.new(:name_blank) if name.blank?

      ApplicationRecord.transaction do
        copy = ExerciseRoutine.new(
          user: adopter,
          name: name,
          source_exercise_routine_id: source.id
        )
        CopyRoutineLines.call(target: copy, source: source)
        copy.save!
        copy
      end
    end
  end
end
