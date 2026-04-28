# frozen_string_literal: true

class PublicDishesController < ApplicationController
  before_action :set_public_dish, only: :show

  def index
    @dishes = Dish.where(publicly_shareable: true).order(:name)
  end

  def show
  end

  private

  def set_public_dish
    @dish = Dish.find_by!(publicly_shareable: true, id: params[:id])
  end
end
