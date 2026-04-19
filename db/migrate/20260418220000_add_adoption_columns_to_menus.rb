# frozen_string_literal: true

class AddAdoptionColumnsToMenus < ActiveRecord::Migration[8.1]
  def change
    add_reference :menus, :source_menu, foreign_key: { to_table: :menus }, null: true
    add_column :menus, :source_sync_fingerprint, :string
    add_column :menus, :adoption_catalog_origin_id, :integer

    add_index :menus, %i[user_id source_menu_id],
      unique: true,
      where: "source_menu_id IS NOT NULL",
      name: "index_menus_adoption_unique_per_user_and_source"
  end
end
