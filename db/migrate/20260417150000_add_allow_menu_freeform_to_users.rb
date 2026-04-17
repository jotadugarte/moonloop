# frozen_string_literal: true

class AddAllowMenuFreeformToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :allow_menu_freeform, :boolean, null: false, default: true
  end
end
