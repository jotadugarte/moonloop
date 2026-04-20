# frozen_string_literal: true

class HabitReminderEvent < ApplicationRecord
  belongs_to :user
  belongs_to :user_habit

  validates :local_date, presence: true
  validates :local_date, uniqueness: { scope: %i[user_id user_habit_id] }
end
