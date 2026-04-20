# frozen_string_literal: true

class CreateCatalogListingFacets < ActiveRecord::Migration[8.1]
  def change
    create_table :catalog_listing_facets do |t|
      t.string :listable_type, null: false
      t.integer :listable_id, null: false
      t.string :goal_phrase, limit: 255
      t.string :difficulty_level, limit: 32
      t.string :normalized_tags, limit: 500
      t.integer :duration_weeks_min
      t.integer :duration_weeks_max

      t.timestamps
    end

    add_index :catalog_listing_facets, %i[listable_type listable_id], unique: true, name: "index_catalog_listing_facets_on_listable"
  end
end
