class CreateRecipes < ActiveRecord::Migration[8.1]
  def change
    create_table :recipes do |t|
      t.references :user, null: false, foreign_key: true
      t.string :name, null: false
      t.text :instructions
      t.boolean :publicly_shareable, null: false, default: false

      t.timestamps
    end
  end
end
