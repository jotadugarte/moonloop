# frozen_string_literal: true

# completed_on stores the user-local calendar day when the habit was marked (see SPEC — Mi Día).
class HabitCompletion < ApplicationRecord
  STATUSES = %w[done failed].freeze

  belongs_to :user_habit

  validates :completed_on, presence: true
  validates :status, presence: true, inclusion: { in: STATUSES }
  validates :completed_on, uniqueness: { scope: :user_habit_id }
  validate :user_habit_must_be_active, on: %i[create update]

  private

  def user_habit_must_be_active
    return if user_habit&.active?

    errors.add(:base, :user_habit_inactive)
  end
end
