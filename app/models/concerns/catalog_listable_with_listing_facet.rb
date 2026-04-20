# frozen_string_literal: true

# Optional public-catalog discovery row (REQ-CAT-001) for Menu, ExerciseRoutine, PhaseProgram.
module CatalogListableWithListingFacet
  extend ActiveSupport::Concern

  included do
    listable_type_for_catalog_facet = name

    # Scoped has_one + polymorphic listable: Rails may skip dependent: :destroy; delete explicitly.
    before_destroy :_destroy_catalog_listing_facet_row, prepend: true

    has_one :catalog_listing_facet,
      -> { where(listable_type: listable_type_for_catalog_facet) },
      class_name: "Catalog::ListingFacet",
      foreign_key: :listable_id

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

  def _destroy_catalog_listing_facet_row
    row = Catalog::ListingFacet.find_by(listable_type: self.class.name, listable_id: id)
    row&.destroy!
  end

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
