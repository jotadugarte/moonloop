class CreateMenus < ActiveRecord::Migration[8.1]
  def change
    create_table :menus do |t|
      t.references :user, null: false, foreign_key: true
      t.string :name, null: false
      t.boolean :publicly_shareable, null: false, default: false

      t.timestamps
    end
  end
end
