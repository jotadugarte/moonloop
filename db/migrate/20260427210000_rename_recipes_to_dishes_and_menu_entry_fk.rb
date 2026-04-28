# frozen_string_literal: true

class RenameRecipesToDishesAndMenuEntryFk < ActiveRecord::Migration[8.1]
  def change
    remove_foreign_key :menu_entries, :recipes
    rename_column :menu_entries, :recipe_id, :dish_id
    rename_index :menu_entries, "index_menu_entries_on_recipe_id", "index_menu_entries_on_dish_id"
    rename_table :recipes, :dishes
    rename_index :dishes, "index_recipes_on_user_id", "index_dishes_on_user_id"
    rename_index :dishes, "index_recipes_on_user_id_and_meal_type", "index_dishes_on_user_id_and_meal_type"
    add_foreign_key :menu_entries, :dishes
  end
end
