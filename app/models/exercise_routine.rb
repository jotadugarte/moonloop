# frozen_string_literal: true

class ExerciseRoutine < ApplicationRecord
  include CatalogListableWithListingFacet

  MAX_LINES_PER_WEEKDAY = 100

  belongs_to :user
  belongs_to :source_exercise_routine, class_name: "ExerciseRoutine", optional: true, inverse_of: :adopted_copies
  has_many :adopted_copies, class_name: "ExerciseRoutine", foreign_key: :source_exercise_routine_id, inverse_of: :source_exercise_routine, dependent: :nullify
  has_many :exercise_routine_lines, -> { order(:weekday, :position) }, dependent: :destroy, inverse_of: :exercise_routine
  has_many :exercise_routine_assignments, dependent: :destroy

  accepts_nested_attributes_for :exercise_routine_lines, allow_destroy: true

  validates :name, presence: true

  normalizes :name, with: -> { _1.strip }

  before_validation :sync_name_normalized

  validate :name_must_be_unique_for_user
  validate :must_have_at_least_one_line
  validate :lines_per_weekday_within_limit
  validates_associated :exercise_routine_lines

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

  def must_have_at_least_one_line
    lines = exercise_routine_lines.reject(&:marked_for_destruction?)
    return if lines.any? { |line| line.label.to_s.strip.present? }

    errors.add(:base, :empty_routine)
  end

  def lines_per_weekday_within_limit
    lines = exercise_routine_lines.reject(&:marked_for_destruction?)
    lines.group_by(&:weekday).each_value do |rows|
      next if rows.size <= MAX_LINES_PER_WEEKDAY

      errors.add(:base, :too_many_lines_on_weekday, max: MAX_LINES_PER_WEEKDAY)
      break
    end
  end
end
