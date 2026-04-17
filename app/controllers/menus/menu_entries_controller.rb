module Menus
  class MenuEntriesController < ApplicationController
    before_action :set_menu

    def create
      outcome = Menus::UpsertEntry.call(
        user: Current.user,
        menu: @menu,
        weekday: menu_entry_params[:weekday],
        meal_type: menu_entry_params[:meal_type],
        recipe_id: menu_entry_params[:recipe_id],
        freeform_text: menu_entry_params[:freeform_text]
      )

      if outcome == :cleared
        @weekday = Integer(menu_entry_params[:weekday])
        @meal_type = menu_entry_params[:meal_type].to_s
        @entry = nil
      else
        @weekday = Integer(menu_entry_params[:weekday])
        @meal_type = menu_entry_params[:meal_type].to_s
        @entry = @menu.menu_entries.find_by!(weekday: @weekday, meal_type: @meal_type)
      end

      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace(
            slot_frame_id(@menu, @weekday, @meal_type),
            partial: "menus/slot",
            locals: { menu: @menu, weekday: @weekday, meal_type: @meal_type, entry: @entry }
          )
        end
        format.html { redirect_to edit_menu_path(@menu) }
      end
    rescue ActiveRecord::RecordInvalid => e
      @weekday = Integer(menu_entry_params[:weekday])
      @meal_type = menu_entry_params[:meal_type].to_s
      @entry =
        if e.record.is_a?(MenuEntry)
          e.record
        else
          @menu.menu_entries.find_by(weekday: @weekday, meal_type: @meal_type)
        end

      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace(
            slot_frame_id(@menu, @weekday, @meal_type),
            partial: "menus/slot",
            locals: { menu: @menu, weekday: @weekday, meal_type: @meal_type, entry: @entry },
            status: :unprocessable_entity
          )
        end
        format.html { redirect_to edit_menu_path(@menu), alert: t("menus.entries.flash.could_not_save") }
      end
    end

    def clear
      weekday = Integer(params[:weekday])
      meal_type = params[:meal_type].to_s

      entry = @menu.menu_entries.find_by(weekday: weekday, meal_type: meal_type)
      entry&.destroy!

      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace(
            slot_frame_id(@menu, weekday, meal_type),
            partial: "menus/slot",
            locals: { menu: @menu, weekday: weekday, meal_type: meal_type, entry: nil }
          )
        end
        format.html { redirect_to edit_menu_path(@menu) }
      end
    end

    private

    def set_menu
      @menu = Current.user.menus.find(params[:menu_id])
    end

    def menu_entry_params
      params.require(:menu_entry).permit(:weekday, :meal_type, :recipe_id, :freeform_text)
    end

    def slot_frame_id(menu, weekday, meal_type)
      helpers.dom_id(menu, "slot_#{weekday}_#{meal_type}")
    end
  end
end
