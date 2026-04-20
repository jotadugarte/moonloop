# frozen_string_literal: true

# [REQ-PHS-001] Unified phase program (bundle); catalog/adoption parity with Menu / ExerciseRoutine.
class PhaseProgram < ApplicationRecord
  include CatalogListableWithListingFacet

  belongs_to :user
  belongs_to :source_phase_program, class_name: "PhaseProgram", optional: true, inverse_of: :adopted_copies
  has_many :adopted_copies, class_name: "PhaseProgram", foreign_key: :source_phase_program_id, inverse_of: :source_phase_program, dependent: :nullify
  has_many :phase_program_assignments, dependent: :destroy

  validates :name, presence: true

  normalizes :name, with: -> { _1.strip }

  before_validation :sync_name_normalized

  validate :name_must_be_unique_for_user

  after_save :_materialize_catalog_listing_facet_duration_from_assignments

  private

  def _materialize_catalog_listing_facet_duration_from_assignments
    Catalog::MaterializePhaseProgramFacetDuration.call(self)
  end

  def sync_name_normalized
    self.name_normalized = name.to_s.strip.downcase
  end

  def name_must_be_unique_for_user
    return if user_id.blank? || name_normalized.blank?

    scope = self.class.where(user_id: user_id, name_normalized: name_normalized)
    scope = scope.where.not(id: id) if persisted?
    errors.add(:name, :taken) if scope.exists?
  end
end
