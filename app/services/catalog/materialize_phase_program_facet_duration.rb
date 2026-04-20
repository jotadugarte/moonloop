# frozen_string_literal: true

module Catalog
  # For PhaseProgram listables only: copies week span from phase_program_assignments into the
  # optional catalog_listing_facet row (REQ-CAT-001). No-op if there is no facet.
  class MaterializePhaseProgramFacetDuration
    def self.call(phase_program)
      new(phase_program).call
    end

    def initialize(phase_program)
      @phase_program = phase_program
    end

    def call
      return unless @phase_program.is_a?(PhaseProgram)

      facet = ListingFacet.find_by(listable_type: "PhaseProgram", listable_id: @phase_program.id)
      return unless facet

      max_end = @phase_program.phase_program_assignments.maximum(:end_week)
      min_start = @phase_program.phase_program_assignments.minimum(:start_week)

      if max_end.nil?
        facet.update!(duration_weeks_min: nil, duration_weeks_max: nil)
      else
        facet.update!(duration_weeks_min: min_start, duration_weeks_max: max_end)
      end
    end
  end
end
