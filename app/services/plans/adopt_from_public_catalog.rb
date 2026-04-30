# frozen_string_literal: true

module Plans
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
      if adopter.plans.where(source_plan_id: source.id).exists?
        raise Error.new(:already_adopted)
      end

      name = chosen_name.to_s.strip
      raise Error.new(:name_blank) if name.blank?

      fp = Plans::ContentFingerprint.for_plan(source)

      ApplicationRecord.transaction do
        copy = Plan.new(
          user: adopter,
          name: name,
          source_plan_id: source.id,
          source_sync_fingerprint: fp,
          adoption_catalog_origin_id: source.id,
          publicly_shareable: false
        )
        copy.save!

        PopulateAssignmentsFromSource.call(
          plan: copy,
          source: source,
          adopter: adopter,
          name_prefix: name
        )

        Catalog::IncrementTemplateAdoptionMetrics.call(source)
        copy
      end
    end
  end
end
