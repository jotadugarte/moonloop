# frozen_string_literal: true

class AddBodyUnitSystemToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :body_unit_system, :string, null: false, default: "metric"
  end
end
