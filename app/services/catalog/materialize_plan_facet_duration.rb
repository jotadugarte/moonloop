# frozen_string_literal: true

module Catalog
  class MaterializePlanFacetDuration
    def self.call(plan)
      return if plan.nil?

      assignments = PlanAssignment.where(plan_id: plan.id)
      facet = Catalog::ListingFacet.find_by(listable_type: plan.class.name, listable_id: plan.id)

      if assignments.empty?
        facet&.update!(duration_weeks_min: nil, duration_weeks_max: nil)
        return
      end

      min_w = assignments.minimum(:start_week)
      max_w = assignments.maximum(:end_week)

      facet ||= plan.build_catalog_listing_facet
      facet.duration_weeks_min = min_w
      facet.duration_weeks_max = max_w
      facet.save!
    end
  end
end
