# frozen_string_literal: true

class AddHabitMetricsToUserHabitsAndHabitCompletions < ActiveRecord::Migration[8.1]
  def change
    add_column :user_habits, :habit_metric_kind, :string, null: false, default: "none"
    add_column :user_habits, :daily_target, :integer, null: false, default: 1
    add_column :habit_completions, :day_progress, :integer, null: false, default: 0
  end
end
