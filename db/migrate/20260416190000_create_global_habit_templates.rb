class CreateGlobalHabitTemplates < ActiveRecord::Migration[8.1]
  def change
    create_table :global_habit_templates do |t|
      t.string :code, null: false
      t.boolean :active, null: false, default: true

      t.timestamps
    end

    add_index :global_habit_templates, :code, unique: true
  end
end

