# frozen_string_literal: true

class CreateHabitCompletions < ActiveRecord::Migration[8.1]
  def change
    create_table :habit_completions do |t|
      t.references :user_habit, null: false, foreign_key: true
      t.date :completed_on, null: false
      t.string :status, null: false

      t.timestamps
    end

    add_index :habit_completions, [ :user_habit_id, :completed_on ], unique: true, name: "index_habit_completions_on_user_habit_and_completed_on"
  end
end
