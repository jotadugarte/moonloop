# frozen_string_literal: true

module Programs
  class AdoptionSyncStatus
    Status = Struct.new(:key, :origin_fingerprint, keyword_init: true)

    def self.for_program(program)
      return Status.new(key: :none) unless program.adoption_catalog_origin_id.present?

      if program.source_phase_program_id.blank?
        return Status.new(key: :unavailable)
      end

      source = program.source_phase_program
      if source.nil?
        return Status.new(key: :unavailable)
      end

      unless source.publicly_shareable?
        return Status.new(key: :unavailable)
      end

      fp = ContentFingerprint.for_program(source)
      if program.source_sync_fingerprint == fp
        Status.new(key: :synced, origin_fingerprint: fp)
      else
        Status.new(key: :pending, origin_fingerprint: fp)
      end
    end
  end
end
