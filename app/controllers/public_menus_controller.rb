# frozen_string_literal: true

class PublicMenusController < ApplicationController
  include AdoptionInvalidRecordFlash

  before_action :set_public_menu, only: %i[show adopt]

  def index
    @menus = Menu.includes(:user).where(publicly_shareable: true).order(:name)
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
