# frozen_string_literal: true

class AddPublicCatalogAdoptionCountersToTemplates < ActiveRecord::Migration[8.1]
  def change
    add_column :menus, :public_catalog_adoptions_count, :integer, null: false, default: 0
    add_column :menus, :public_catalog_distinct_adopters_count, :integer, null: false, default: 0

    add_column :exercise_routines, :public_catalog_adoptions_count, :integer, null: false, default: 0
    add_column :exercise_routines, :public_catalog_distinct_adopters_count, :integer, null: false, default: 0

    add_column :phase_programs, :public_catalog_adoptions_count, :integer, null: false, default: 0
    add_column :phase_programs, :public_catalog_distinct_adopters_count, :integer, null: false, default: 0
  end
end
