# frozen_string_literal: true

module ExerciseRoutines
  class AdoptionSyncStatus
    Status = Struct.new(:key, :origin_fingerprint, keyword_init: true)

    def self.for_routine(routine)
      return Status.new(key: :none) unless routine.adoption_catalog_origin_id.present?

      if routine.source_exercise_routine_id.blank?
        return Status.new(key: :unavailable)
      end

      source = routine.source_exercise_routine
      if source.nil?
        return Status.new(key: :unavailable)
      end

      unless source.publicly_shareable?
        return Status.new(key: :unavailable)
      end

      fp = ContentFingerprint.for_routine(source)
      if routine.source_sync_fingerprint == fp
        Status.new(key: :synced, origin_fingerprint: fp)
      else
        Status.new(key: :pending, origin_fingerprint: fp)
      end
    end
  end
end
