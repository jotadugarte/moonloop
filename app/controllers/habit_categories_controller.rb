class HabitCategoriesController < ApplicationController
  before_action :set_habit_category, only: %i[edit update destroy]

  def index
    @habit_category = HabitCategory.new
    @habit_categories = Current.user.habit_categories.order(created_at: :asc)
  end

  def create
    @habit_category = Current.user.habit_categories.new(habit_category_params)

    if @habit_category.save
      redirect_to habit_categories_path, notice: "Category created"
    else
      @habit_categories = Current.user.habit_categories.order(created_at: :asc)
      render :index, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @habit_category.update(habit_category_params)
      redirect_to habit_categories_path, notice: "Category updated"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    if @habit_category.destroy
      redirect_to habit_categories_path, notice: "Category deleted"
    else
      base_message = @habit_category.errors[:base].presence&.to_sentence
      redirect_to habit_categories_path, alert: (base_message || @habit_category.errors.full_messages.to_sentence)
    end
  end

  private

  def set_habit_category
    @habit_category = Current.user.habit_categories.find(params[:id])
  end

  def habit_category_params
    params.require(:habit_category).permit(:name)
  end
end

