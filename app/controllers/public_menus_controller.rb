# frozen_string_literal: true

class PublicMenusController < ApplicationController
  include AdoptionInvalidRecordFlash
  include CatalogPublicIndexSort

  before_action :set_public_menu, only: %i[show adopt]

  def index
    base = Menu.where(publicly_shareable: true)
    filtered = Catalog::ApplyPublicListingFilters.call(base, params)
    @menus = filtered.includes(:user).order(catalog_public_index_order)
  end

  def show
  end

  def adopt
    copy = Menus::AdoptFromPublicCatalog.call(
      adopter: Current.user,
      source: @menu,
      chosen_name: params.require(:name)
    )
    redirect_to edit_menu_path(copy), notice: t("public_menus.adopt.success")
  rescue Menus::AdoptFromPublicCatalog::Error => e
    redirect_to public_menu_path(@menu),
      alert: t("public_menus.adopt.errors.#{e.key}")
  rescue ActionController::ParameterMissing
    redirect_to public_menu_path(@menu),
      alert: t("public_menus.adopt.errors.name_blank")
  rescue ActiveRecord::RecordInvalid => e
    redirect_to public_menu_path(@menu), alert: adoption_invalid_alert_for(e.record)
  end

  private

  def set_public_menu
    @menu = Menu.find_by!(publicly_shareable: true, id: params[:id])
  end
end
