# frozen_string_literal: true

module Plans
  class AdoptionSyncStatus
    Status = Struct.new(:key, :origin_fingerprint, keyword_init: true)

    def self.for_plan(plan)
      return Status.new(key: :none) unless plan.adoption_catalog_origin_id.present?

      if plan.source_plan_id.blank?
        return Status.new(key: :unavailable)
      end

      source = plan.source_plan
      if source.nil?
        return Status.new(key: :unavailable)
      end

      unless source.publicly_shareable?
        return Status.new(key: :unavailable)
      end

      fp = ContentFingerprint.for_plan(source)
      if plan.source_sync_fingerprint == fp
        Status.new(key: :synced, origin_fingerprint: fp)
      else
        Status.new(key: :pending, origin_fingerprint: fp)
      end
    end
  end
end
