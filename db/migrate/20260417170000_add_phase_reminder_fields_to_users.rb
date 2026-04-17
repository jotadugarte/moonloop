# frozen_string_literal: true

class AddPhaseReminderFieldsToUsers < ActiveRecord::Migration[8.1]
  def change
    change_table :users, bulk: true do |t|
      t.boolean :phase_reminder_in_app, default: true, null: false
      t.boolean :phase_reminder_email, default: true, null: false
      t.date :phase_reminder_dismissed_on
    end
  end
end
