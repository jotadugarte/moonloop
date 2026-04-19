# frozen_string_literal: true

class AddMarkedFailedByUserToHabitCompletions < ActiveRecord::Migration[8.1]
  def change
    add_column :habit_completions, :marked_failed_by_user, :boolean, default: false, null: false
  end
end
