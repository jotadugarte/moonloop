# frozen_string_literal: true

class AddNameNormalizedToMenus < ActiveRecord::Migration[8.1]
  def up
    add_column :menus, :name_normalized, :string

    Menu.reset_column_information
    Menu.find_each do |menu|
      menu.update_column(:name_normalized, menu.name.to_s.strip.downcase)
    end

    change_column_null :menus, :name_normalized, false
    add_index :menus, %i[user_id name_normalized],
      unique: true,
      name: "index_menus_on_user_id_and_name_normalized"
  end

  def down
    remove_index :menus, name: "index_menus_on_user_id_and_name_normalized"
    remove_column :menus, :name_normalized
  end
end
