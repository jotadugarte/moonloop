# frozen_string_literal: true

# [REQ-PHS-001] One contiguous week range within a plan, pairing a Menu and ExerciseRoutine (same owner as the plan).
class PlanAssignment < ApplicationRecord
  belongs_to :plan
  belongs_to :menu
  belongs_to :exercise_routine

  validates :start_week, :end_week, presence: true
  validates :start_week, :end_week, numericality: { only_integer: true, greater_than: 0 }
  validate :end_week_gte_start_week
  validate :menu_must_belong_to_plan_owner
  validate :exercise_routine_must_belong_to_plan_owner
  validate :ranges_must_not_overlap

  after_commit :_materialize_plan_catalog_facet_duration

  private

  def _materialize_plan_catalog_facet_duration
    Catalog::MaterializePlanFacetDuration.call(plan)
  end

  def end_week_gte_start_week
    return if start_week.blank? || end_week.blank?
    return if end_week >= start_week

    errors.add(:end_week, :before_start_week)
  end

  def menu_must_belong_to_plan_owner
    return if menu.blank? || plan.blank?
    return if menu.user_id == plan.user_id

    errors.add(:menu_id, :must_match_user)
  end

  def exercise_routine_must_belong_to_plan_owner
    return if exercise_routine.blank? || plan.blank?
    return if exercise_routine.user_id == plan.user_id

    errors.add(:exercise_routine_id, :must_match_user)
  end

  def ranges_must_not_overlap
    return if start_week.blank? || end_week.blank? || plan_id.blank?

    range = start_week..end_week
    scope = PlanAssignment.where(plan_id: plan_id)
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

