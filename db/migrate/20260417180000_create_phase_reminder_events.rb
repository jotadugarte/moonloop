# frozen_string_literal: true

class CreatePhaseReminderEvents < ActiveRecord::Migration[8.1]
  def change
    create_table :phase_reminder_events do |t|
      t.references :user, null: false, foreign_key: true
      t.string :kind, null: false
      t.date :local_date, null: false
      t.timestamps
    end

    add_index :phase_reminder_events,
              %i[user_id kind local_date],
              unique: true,
              name: "index_phase_reminder_events_uniqueness"
  end
end
