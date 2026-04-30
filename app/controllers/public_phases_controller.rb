# frozen_string_literal: true

class PublicPhasesController < ApplicationController
  include CatalogPublicIndexSort

  before_action :set_public_phase, only: :show

  def index
    base = Phase.where(publicly_shareable: true)
    filtered = Catalog::ApplyPublicListingFilters.call(base, params)
    @phases = filtered.includes(:user).order(catalog_public_index_order)
  end

  def show
  end

  private

  def set_public_phase
    @phase = Phase.find_by!(publicly_shareable: true, id: params[:id])
  end
end

