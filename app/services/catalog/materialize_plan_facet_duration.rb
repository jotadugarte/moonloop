# frozen_string_literal: true

module Catalog
  class MaterializePlanFacetDuration
    def self.call(plan)
      return if plan.nil?

      facet = plan.catalog_listing_facet
      assignments = plan.plan_assignments

      if assignments.empty?
        facet&.update!(duration_weeks_min: nil, duration_weeks_max: nil)
        return
      end

      min_w = assignments.minimum(:start_week)
      max_w = assignments.maximum(:end_week)

      facet = plan.catalog_listing_facet || plan.build_catalog_listing_facet
      facet.duration_weeks_min = min_w
      facet.duration_weeks_max = max_w
      facet.save!
    end
  end
end
