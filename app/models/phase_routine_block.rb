# frozen_string_literal: true

class PhaseRoutineBlock < ApplicationRecord
  belongs_to :phase
  belongs_to :exercise_routine

  validates :start_week, :end_week, presence: true
  validate :end_week_must_not_be_before_start_week
  validate :routine_must_match_phase_user

  private

  def end_week_must_not_be_before_start_week
    return if start_week.blank? || end_week.blank?
    return if end_week >= start_week

    errors.add(:end_week, :before_start_week)
  end

  def routine_must_match_phase_user
    return if phase.blank? || exercise_routine.blank?
    return if phase.user_id == exercise_routine.user_id

    errors.add(:exercise_routine_id, :must_match_user)
  end
end
