# frozen_string_literal: true

class PhaseMenuBlock < ApplicationRecord
  belongs_to :phase
  belongs_to :menu

  validates :start_week, :end_week, presence: true
  validate :end_week_must_not_be_before_start_week
  validate :range_must_not_overlap_siblings
  validate :menu_must_match_phase_user

  private

  def end_week_must_not_be_before_start_week
    return if start_week.blank? || end_week.blank?
    return if end_week >= start_week

    errors.add(:end_week, :before_start_week)
  end

  def range_must_not_overlap_siblings
    return if phase_id.blank? || start_week.blank? || end_week.blank?

    scope = self.class.where(phase_id: phase_id)
    scope = scope.where.not(id: id) if persisted?
    overlap = scope.where("start_week <= ? AND end_week >= ?", end_week, start_week).exists?
    errors.add(:base, :range_overlap) if overlap
  end

  def menu_must_match_phase_user
    return if phase.blank? || menu.blank?
    return if phase.user_id == menu.user_id

    errors.add(:menu_id, :must_match_user)
  end
end

