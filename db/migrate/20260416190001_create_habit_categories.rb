class CreateHabitCategories < ActiveRecord::Migration[8.1]
  def change
    create_table :habit_categories do |t|
      t.references :user, null: false, foreign_key: true
      t.string :name, null: false
      t.string :name_normalized, null: false

      t.timestamps
    end

    add_index :habit_categories, [:user_id, :name_normalized], unique: true
  end
end

