# frozen_string_literal: true

class DishesController < ApplicationController
  before_action :set_dish, only: %i[show edit update destroy]

  def index
    @dishes = Current.user.dishes.order(:name)
  end

  def show
  end

  def new
    @dish = Current.user.dishes.new
  end

  def create
    attrs = dish_params.except(:remove_image)
    @dish = Current.user.dishes.new(attrs)

    if save_dish_and_attach_placeholder
      redirect_to dish_path(@dish), notice: t("dishes.flash.created")
    else
      render :new, status: :unprocessable_content
    end
  end

  def edit
  end

  def update
    attrs = dish_params
    remove_image = ActiveModel::Type::Boolean.new.cast(attrs.delete(:remove_image))
    incoming_image = attrs[:image]

    if @dish.update(attrs)
      if remove_image && incoming_image.blank?
        @dish.image.purge if @dish.image.attached?
        attach_placeholder_image_if_missing
      end
      redirect_to dish_path(@dish), notice: t("dishes.flash.updated")
    else
      render :edit, status: :unprocessable_content
    end
  end

  def destroy
    @dish.destroy!
    redirect_to dishes_path, notice: t("dishes.flash.destroyed")
  end

  private

  def set_dish
    @dish = Current.user.dishes.includes(image_attachment: :blob).find(params[:id])
  end

  def dish_params
    params.require(:dish).permit(:name, :instructions, :publicly_shareable, :meal_type, :image, :remove_image)
  end

  def attach_placeholder_image_if_missing
    return if @dish.image.attached?

    meal_key = Menus::MealType.new(@dish.meal_type).key
    path = Rails.root.join("app/assets/images/menus/fallback_#{meal_key}.svg")
    @dish.image.attach(
      io: StringIO.new(File.binread(path)),
      filename: "fallback_#{meal_key}.svg",
      content_type: "image/svg+xml"
    )
  end

  def save_dish_and_attach_placeholder
    Dish.transaction do
      return false unless @dish.save

      attach_placeholder_image_if_missing
      true
    end
  end
end
