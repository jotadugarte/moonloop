class AddMealTypeToRecipes < ActiveRecord::Migration[8.1]
  def change
    add_column :recipes, :meal_type, :string, null: false, default: "desayuno"
    add_index :recipes, %i[user_id meal_type]
  end
end
