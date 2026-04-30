# frozen_string_literal: true

class BackfillCatalogListingFacetsPlanListableType < ActiveRecord::Migration[8.1]
  def up
    execute <<-SQL.squish
      UPDATE catalog_listing_facets
      SET listable_type = 'Plan'
      WHERE listable_type = 'PhaseProgram'
    SQL
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
