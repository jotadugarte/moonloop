# frozen_string_literal: true

class Phase < ApplicationRecord
  include CatalogListableWithListingFacet

  belongs_to :user
  belongs_to :source_phase, class_name: "Phase", optional: true, inverse_of: :adopted_copies
  has_many :adopted_copies, class_name: "Phase", foreign_key: :source_phase_id, inverse_of: :source_phase, dependent: :nullify
  has_many :phase_menu_blocks, dependent: :destroy
  has_many :phase_routine_blocks, dependent: :destroy

  validates :name, presence: true
  validates :weeks_total, numericality: { only_integer: true, greater_than_or_equal_to: 1 }

  normalizes :name, with: -> { _1.strip }

  before_validation :sync_name_normalized

  validate :name_must_be_unique_for_user
  validate :blocks_must_be_valid

  private

  def sync_name_normalized
    self.name_normalized = name.to_s.strip.downcase
  end

  def name_must_be_unique_for_user
    return if user_id.blank? || name_normalized.blank?

    scope = self.class.where(user_id: user_id, name_normalized: name_normalized)
    scope = scope.where.not(id: id) if persisted?
    errors.add(:name, :taken) if scope.exists?
  end

  def blocks_must_be_valid
    return if weeks_total.blank?

    PhaseBlocks::CoverageValidator.call(phase: self)
  end
end

