# frozen_string_literal: true

class UpdateActiveStorageRecipeTypeToDish < ActiveRecord::Migration[8.1]
  def up
    ActiveStorage::Attachment.where(record_type: "Recipe").update_all(record_type: "Dish")
  end

  def down
    ActiveStorage::Attachment.where(record_type: "Dish").update_all(record_type: "Recipe")
  end
end
