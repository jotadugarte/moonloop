# frozen_string_literal: true

# Shared sort contract for authenticated public catalog index pages (REQ-CAT-001).
module CatalogPublicIndexSort
  extend ActiveSupport::Concern

  private

  ALLOWED_CATALOG_SORTS = %w[name popular].freeze

  def catalog_public_index_order
    sort = params[:sort].to_s.strip.downcase
    sort = "name" unless ALLOWED_CATALOG_SORTS.include?(sort)

    if sort == "popular"
      { public_catalog_adoptions_count: :desc, name: :asc, id: :asc }
    else
      { name: :asc, id: :asc }
    end
  end
end
