class AddFrequencyToUserHabits < ActiveRecord::Migration[8.1]
  def change
    add_column :user_habits, :frequency_type, :string, null: false, default: "daily"
    add_column :user_habits, :frequency_params, :json, null: false, default: {}
    add_column :user_habits, :activation_date, :date

    add_index :user_habits, :frequency_type
    add_index :user_habits, :activation_date
  end
end
