# frozen_string_literal: true

class PublicMenusController < ApplicationController
  before_action :set_public_menu, only: %i[show]

  def index
    @menus = Menu.where(publicly_shareable: true).order(:name)
  end

  def show
  end

  private

  def set_public_menu
    @menu = Menu.find_by!(publicly_shareable: true, id: params[:id])
  end
end
