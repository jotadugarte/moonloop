# frozen_string_literal: true

class MenusController < ApplicationController
  before_action :set_menu, only: %i[edit update accept_source_update]

  def index
    @menu = Menu.new
    @menus = Current.user.menus.order(created_at: :asc)
  end

  def create
    @menu = Current.user.menus.new(menu_params)

    if @menu.save
      redirect_to edit_menu_path(@menu), notice: t("menus.flash.created")
    else
      @menus = Current.user.menus.order(created_at: :asc)
      render :index, status: :unprocessable_content
    end
  end

  def edit
    set_adoption_sync_status
    load_menu_editor
  end

  def update
    if @menu.update(menu_params)
      redirect_to edit_menu_path(@menu), notice: t("menus.flash.updated")
    else
      set_adoption_sync_status
      load_menu_editor
      render :edit, status: :unprocessable_content
    end
  end

  def accept_source_update
    Menus::ApplyAdoptionSourceSync.call(
      copy: @menu,
      expected_origin_fingerprint: params[:expected_origin_fingerprint].presence
    )
    redirect_to edit_menu_path(@menu), notice: t("menus.flash.source_sync_applied")
  rescue Menus::ApplyAdoptionSourceSync::Error => e
    redirect_to edit_menu_path(@menu),
      alert: t("menus.adoption_sync.errors.#{e.key}")
  end

  private

  def set_adoption_sync_status
    @adoption_sync_status = Menus::AdoptionSyncStatus.for_menu(@menu)
  end

  def set_menu
    @menu = Current.user.menus.find(params[:id])
  end

  def load_menu_editor
    @meal_types = Menus::MealType::KEYS
    @entries_by_slot = @menu.menu_entries
      .includes(dish: { image_attachment: :blob })
      .index_by { |e| [ e.weekday, e.meal_type ] }

    @dishes = Current.user.dishes.order(:name).to_a
    @dishes_by_meal_type = @dishes.group_by(&:meal_type)
  end

  def menu_params
    params.require(:menu).permit(
      :name,
      :publicly_shareable,
      catalog_listing_facet_attributes: %i[
        id goal_phrase difficulty_level normalized_tags duration_weeks_min duration_weeks_max
      ]
    )
  end
end
