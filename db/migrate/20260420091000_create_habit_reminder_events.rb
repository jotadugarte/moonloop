# frozen_string_literal: true

class CreateHabitReminderEvents < ActiveRecord::Migration[8.1]
  def change
    create_table :habit_reminder_events do |t|
      t.references :user, null: false, foreign_key: true
      t.references :user_habit, null: false, foreign_key: true
      t.date :local_date, null: false
      t.timestamps
    end

    add_index :habit_reminder_events,
              %i[user_id user_habit_id local_date],
              unique: true,
              name: "index_habit_reminder_events_uniqueness"
  end
end

