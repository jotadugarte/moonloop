# frozen_string_literal: true

module Catalog
  # Increments template-level catalog counters on successful adoption (REQ-CAT-001).
  module IncrementTemplateAdoptionMetrics
    def self.call(template)
      unless template.is_a?(Menu) || template.is_a?(ExerciseRoutine) || template.is_a?(PhaseProgram) || template.is_a?(Phase)
        raise ArgumentError, "expected Menu, ExerciseRoutine, PhaseProgram, or Phase, got #{template.class}"
      end

      sql = "public_catalog_adoptions_count = public_catalog_adoptions_count + 1, " \
            "public_catalog_distinct_adopters_count = public_catalog_distinct_adopters_count + 1"
      template.class.where(id: template.id).update_all(sql)
    end
  end
end
