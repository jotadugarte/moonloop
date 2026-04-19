# frozen_string_literal: true

# completed_on stores the user-local calendar day when the habit was marked (see SPEC — Mi Día).
class HabitCompletion < ApplicationRecord
  STATUSES = %w[done failed].freeze
  DAY_PROGRESS_MAX = UserHabit::DAILY_TARGET_MAX

  belongs_to :user_habit

  validates :completed_on, presence: true
  validates :status, presence: true, inclusion: { in: STATUSES }
  validates :completed_on, uniqueness: { scope: :user_habit_id }
  validates :day_progress,
    numericality: {
      only_integer: true,
      greater_than_or_equal_to: 0,
      less_than_or_equal_to: DAY_PROGRESS_MAX
    }
  validate :user_habit_must_be_active, on: %i[create update]
  validate :day_progress_must_be_zero_for_none_metric

  private

  def day_progress_must_be_zero_for_none_metric
    return if user_habit.blank?
    return unless user_habit.habit_metric_kind == "none"
    return if day_progress.to_i.zero?

    errors.add(:day_progress, :must_be_zero_when_metric_none)
  end

  def user_habit_must_be_active
    return if user_habit&.active?

    errors.add(:base, :user_habit_inactive)
  end
end
