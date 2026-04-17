# frozen_string_literal: true

class ExerciseRoutineAssignment < ApplicationRecord
  belongs_to :user
  belongs_to :exercise_routine

  validates :start_week, :end_week, presence: true
  validates :start_week, :end_week, numericality: { only_integer: true, greater_than: 0 }
  validate :end_week_gte_start_week
  validate :exercise_routine_must_belong_to_user
  validate :ranges_must_not_overlap

  private

  def end_week_gte_start_week
    return if start_week.blank? || end_week.blank?
    return if end_week >= start_week

    errors.add(:end_week, :before_start_week)
  end

  def exercise_routine_must_belong_to_user
    return if exercise_routine.blank? || user.blank?
    return if exercise_routine.user_id == user_id

    errors.add(:exercise_routine_id, :must_match_user)
  end

  def ranges_must_not_overlap
    return if start_week.blank? || end_week.blank? || user_id.blank?

    range = start_week..end_week
    scope = ExerciseRoutineAssignment.where(user_id: user_id)
    scope = scope.where.not(id: id) if persisted?
    scope.find_each do |other|
      next unless ranges_overlap?(range, other.start_week..other.end_week)

      errors.add(:base, :range_overlap)
      break
    end
  end

  def ranges_overlap?(a, b)
    a.begin <= b.end && b.begin <= a.end
  end
end
