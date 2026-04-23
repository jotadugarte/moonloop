class CreateUserHabits < ActiveRecord::Migration[8.1]
  def change
    create_table :user_habits do |t|
      t.references :user, null: false, foreign_key: true
      t.references :habit_category, null: false, foreign_key: true
      t.references :global_habit_template, null: true, foreign_key: true

      t.string :name, null: false
      t.string :name_normalized, null: false
      t.boolean :active, null: false, default: true

      t.timestamps
    end

    # Enforce "unique among active only" at the DB level.
    add_index :user_habits,
              [ :user_id, :name_normalized ],
              unique: true,
              where: "active = true",
              name: "idx_user_habits_unique_active_name_per_user"
  end
end
