# frozen_string_literal: true

class ExerciseRoutine < ApplicationRecord
  belongs_to :user
  has_many :exercise_routine_lines, -> { order(:weekday, :position) }, dependent: :destroy, inverse_of: :exercise_routine
  has_many :exercise_routine_assignments, dependent: :destroy

  accepts_nested_attributes_for :exercise_routine_lines, allow_destroy: true

  validates :name, presence: true

  normalizes :name, with: -> { _1.strip }

  before_validation :sync_name_normalized

  validate :name_must_be_unique_for_user
  validate :must_have_at_least_one_line
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
end
