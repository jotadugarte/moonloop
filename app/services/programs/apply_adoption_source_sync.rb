# frozen_string_literal: true

module Programs
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

      source = copy.source_phase_program
      if source.nil? || !source.publicly_shareable?
        raise Error.new(:source_unavailable)
      end

      current_fp = ContentFingerprint.for_program(source)
      if expected_origin_fingerprint.present? && expected_origin_fingerprint != current_fp
        raise Error.new(:origin_changed_retry)
      end

      return copy if copy.source_sync_fingerprint == current_fp

      ApplicationRecord.transaction do
        copy.reload
        source.reload
        PopulateAssignmentsFromSource.call(
          program: copy,
          source: source,
          adopter: copy.user,
          name_prefix: copy.name
        )
        copy.source_sync_fingerprint = current_fp
        copy.save!
      end
      copy.reload
    end
  end
end
