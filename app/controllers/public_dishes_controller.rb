# frozen_string_literal: true

class PublicDishesController < ApplicationController
  before_action :set_public_recipe, only: :show

  def index
    @recipes = Recipe.where(publicly_shareable: true).order(:name)
  end

  def show
  end

  private

  def set_public_recipe
    @recipe = Recipe.find_by!(publicly_shareable: true, id: params[:id])
  end
end
