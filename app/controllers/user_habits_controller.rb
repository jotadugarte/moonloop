class UserHabitsController < ApplicationController
  before_action :set_user_habit, only: %i[activate deactivate]

  def index
    @categories = Current.user.habit_categories.order(created_at: :asc)
    @habits_by_category = Current.user.user_habits.includes(:habit_category).order(created_at: :asc).group_by(&:habit_category)

    @user_habit = Current.user.user_habits.new
    @templates = GlobalHabitTemplate.order(code: :asc)
  end

  def create
    @user_habit = Current.user.user_habits.new(user_habit_params)

    if @user_habit.save
      redirect_to user_habits_path, notice: t("user_habits.flash.created")
    else
      @categories = Current.user.habit_categories.order(created_at: :asc)
      @habits_by_category = Current.user.user_habits.includes(:habit_category).order(created_at: :asc).group_by(&:habit_category)
      @templates = GlobalHabitTemplate.order(code: :asc)
      render :index, status: :unprocessable_entity
    end
  end

  def create_from_template
    template = GlobalHabitTemplate.find(params.require(:template_id))
    category = Current.user.habit_categories.find(params.require(:habit_category_id))

    habit = Habits::AddFromTemplateService.new(user: Current.user, template: template, category: category).call

    if habit.persisted?
      redirect_to user_habits_path, notice: t("user_habits.flash.added_from_template")
    else
      redirect_to user_habits_path, alert: habit.errors.full_messages.to_sentence
    end
  end

  def deactivate
    @user_habit.update!(active: false)
    redirect_to user_habits_path, notice: t("user_habits.flash.deactivated")
  end

  def activate
    @user_habit.update!(active: true)
    redirect_to user_habits_path, notice: t("user_habits.flash.activated")
  end

  private

  def set_user_habit
    @user_habit = Current.user.user_habits.find(params[:id])
  end

  def user_habit_params
    params.require(:user_habit).permit(:habit_category_id, :name).merge(active: true)
  end
end

