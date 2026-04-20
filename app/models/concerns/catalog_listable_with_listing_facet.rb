# frozen_string_literal: true

# Optional public-catalog discovery row (REQ-CAT-001) for Menu, ExerciseRoutine, PhaseProgram.
module CatalogListableWithListingFacet
  extend ActiveSupport::Concern

  included do
    # FK lives on catalog_listing_facets; scope listable_type explicitly so dependent :destroy
    # finds the row (has_one ... as: :listable can miss it with namespaced class_name).
    listable_type_for_catalog_facet = name

    has_one :catalog_listing_facet,
      -> { where(listable_type: listable_type_for_catalog_facet) },
      class_name: "Catalog::ListingFacet",
      foreign_key: :listable_id,
      inverse_of: :listable,
      dependent: :destroy

    accepts_nested_attributes_for :catalog_listing_facet,
      reject_if: lambda { |attrs|
        h = attrs.stringify_keys
        h["id"].blank? &&
          %w[goal_phrase difficulty_level normalized_tags duration_weeks_min duration_weeks_max].all? { |k| h[k].blank? }
      }

    validates_associated :catalog_listing_facet
    after_save :_prune_blank_catalog_listing_facet
  end

  private

  def _prune_blank_catalog_listing_facet
    f = catalog_listing_facet
    return unless f&.persisted?

    f.destroy! if _facet_all_blank?(f)
  end

  def _facet_all_blank?(f)
    f.goal_phrase.blank? &&
      f.difficulty_level.blank? &&
      f.normalized_tags.blank? &&
      f.duration_weeks_min.nil? &&
      f.duration_weeks_max.nil?
  end
end
