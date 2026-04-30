# frozen_string_literal: true

module Phases
  class AdoptionSyncStatus
    Status = Struct.new(:key, :origin_fingerprint, keyword_init: true)

    def self.for_phase(phase)
      return Status.new(key: :none) unless phase.adoption_catalog_origin_id.present?

      if phase.source_phase_id.blank?
        return Status.new(key: :unavailable)
      end

      source = phase.source_phase
      if source.nil? || !source.publicly_shareable?
        return Status.new(key: :unavailable)
      end

      fp = ContentFingerprint.for_phase(source)
      if phase.source_sync_fingerprint == fp
        Status.new(key: :synced, origin_fingerprint: fp)
      else
        Status.new(key: :pending, origin_fingerprint: fp)
      end
    end
  end
end
