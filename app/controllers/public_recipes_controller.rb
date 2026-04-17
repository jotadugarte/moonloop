class PublicRecipesController < ApplicationController
  def index
    @recipes = Recipe.where(publicly_shareable: true).order(:name)
  end
end
