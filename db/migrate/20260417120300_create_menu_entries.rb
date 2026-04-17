class CreateMenuEntries < ActiveRecord::Migration[8.1]
  def change
    create_table :menu_entries do |t|
      t.references :menu, null: false, foreign_key: true
      t.references :recipe, null: true, foreign_key: true

      t.integer :weekday, null: false
      t.string :meal_type, null: false
      t.text :freeform_text

      t.timestamps
    end

    add_index :menu_entries,
              [ :menu_id, :weekday, :meal_type ],
              unique: true,
              name: "index_menu_entries_on_menu_weekday_meal_type"
  end
end
