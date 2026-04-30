# frozen_string_literal: true

module Catalog
  class MaterializePlanFacetDuration
    def self.call(plan)
      return if plan.nil?

      assignments = plan.plan_assignments
      return if assignments.empty?

      min_w = assignments.minimum(:start_week)
      max_w = assignments.maximum(:end_week)

      facet = plan.catalog_listing_facet || plan.build_catalog_listing_facet
      facet.duration_weeks_min = min_w
      facet.duration_weeks_max = max_w
      facet.save!
    end
  end
end

