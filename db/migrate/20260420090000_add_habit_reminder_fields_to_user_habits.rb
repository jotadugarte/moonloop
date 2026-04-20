class AddHabitReminderFieldsToUserHabits < ActiveRecord::Migration[8.1]
  def change
    add_column :user_habits, :reminder_enabled, :boolean, null: false, default: false
    add_column :user_habits, :reminder_time_of_day, :string, null: true
    add_column :user_habits, :reminder_email, :boolean, null: false, default: false
    add_column :user_habits, :reminder_web_push, :boolean, null: false, default: false

    add_index :user_habits, [ :reminder_enabled, :reminder_time_of_day ], name: "idx_user_habits_reminder_slot"
  end
end
