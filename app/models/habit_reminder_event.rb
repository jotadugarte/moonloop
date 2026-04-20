# frozen_string_literal: true

class HabitReminderEvent < ApplicationRecord
  belongs_to :user
  belongs_to :user_habit

  validates :local_date, presence: true
  # Uniqueness is enforced by DB index `index_habit_reminder_events_uniqueness` so
  # duplicate inserts raise RecordNotUnique (processor idempotency); avoid a model-level
  # uniqueness validation that would raise RecordInvalid before hitting the DB.
end
