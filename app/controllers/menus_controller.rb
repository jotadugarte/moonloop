class MenusController < ApplicationController
  before_action :set_menu, only: %i[edit]

  def index
    @menu = Menu.new
    @menus = Current.user.menus.order(created_at: :asc)
  end

  def create
    @menu = Current.user.menus.new(menu_params)

    if @menu.save
      redirect_to menus_path, notice: t("menus.flash.created")
    else
      @menus = Current.user.menus.order(created_at: :asc)
      render :index, status: :unprocessable_entity
    end
  end

  def edit
    @meal_types = Menus::MealType::KEYS
    @entries_by_slot = @menu.menu_entries.index_by { |e| [ e.weekday, e.meal_type ] }
  end

  private

  def set_menu
    @menu = Current.user.menus.find(params[:id])
  end

  def menu_params
    params.require(:menu).permit(:name)
  end
end
