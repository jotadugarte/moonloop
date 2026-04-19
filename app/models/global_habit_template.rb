# frozen_string_literal: true

class GlobalHabitTemplate < ApplicationRecord
  has_many :user_habits, dependent: :restrict_with_error

  validates :code, presence: true, uniqueness: true
  validates :suggested_habit_metric_kind, inclusion: { in: UserHabit::METRIC_KINDS }
  validates :suggested_daily_target,
    numericality: {
      only_integer: true,
      greater_than_or_equal_to: 1,
      less_than_or_equal_to: UserHabit::DAILY_TARGET_MAX
    }

  normalizes :code, with: -> { _1.strip.downcase }

  before_validation :normalize_suggested_metrics

  private

  def normalize_suggested_metrics
    self.suggested_habit_metric_kind = "none" if suggested_habit_metric_kind.blank?
    self.suggested_daily_target = 1 if suggested_habit_metric_kind == "none"
  end
end
