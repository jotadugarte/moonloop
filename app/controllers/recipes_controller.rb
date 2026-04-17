# frozen_string_literal: true

class RecipesController < ApplicationController
  before_action :set_recipe, only: %i[show edit update destroy]

  def index
    @recipes = Current.user.recipes.order(:name)
  end

  def show
  end

  def new
    @recipe = Current.user.recipes.new
  end

  def create
    @recipe = Current.user.recipes.new(recipe_params.except(:remove_image))

    if @recipe.save
      redirect_to recipe_path(@recipe), notice: t("recipes.flash.created")
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    attrs = recipe_params
    remove_image = ActiveModel::Type::Boolean.new.cast(attrs.delete(:remove_image))
    incoming_image = attrs[:image]

    if @recipe.update(attrs)
      if remove_image && incoming_image.blank?
        @recipe.image.purge if @recipe.image.attached?
      end
      redirect_to recipe_path(@recipe), notice: t("recipes.flash.updated")
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @recipe.destroy!
    redirect_to recipes_path, notice: t("recipes.flash.destroyed")
  end

  private

  def set_recipe
    @recipe = Current.user.recipes.includes(image_attachment: :blob).find(params[:id])
  end

  def recipe_params
    params.require(:recipe).permit(:name, :instructions, :publicly_shareable, :image, :remove_image)
  end
end
