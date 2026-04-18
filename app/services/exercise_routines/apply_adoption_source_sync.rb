# frozen_string_literal: true

module ExerciseRoutines
  class ApplyAdoptionSourceSync
    class Error < StandardError
      attr_reader :key

      def initialize(key)
        @key = key
        super()
      end
    end

    def self.call(copy:, expected_origin_fingerprint: nil)
      raise Error.new(:not_adopted_copy) if copy.adoption_catalog_origin_id.blank?

      source = copy.source_exercise_routine
      if source.nil? || !source.publicly_shareable?
        raise Error.new(:source_unavailable)
      end

      current_fp = ContentFingerprint.for_routine(source)
      if expected_origin_fingerprint.present? && expected_origin_fingerprint != current_fp
        raise Error.new(:origin_changed_retry)
      end

      if copy.source_sync_fingerprint == current_fp
        return copy
      end

      ApplicationRecord.transaction do
        copy.reload
        source.reload
        copy.exercise_routine_lines.destroy_all
        CopyRoutineLines.call(target: copy.reload, source: source)
        copy.source_sync_fingerprint = current_fp
        copy.save!
      end
      copy.reload
    end
  end
end
