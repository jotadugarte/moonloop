module Menus
  class MenuEntriesController < ApplicationController
    before_action :set_menu

    def create
      run_upsert
      respond_after_upsert
    rescue ActiveRecord::RecordInvalid => e
      assign_invalid_entry(e)
      respond_after_upsert(status: :unprocessable_content)
    end

    def clear
      weekday = Integer(params[:weekday])
      meal_type = params[:meal_type].to_s

      entry = @menu.menu_entries.find_by(weekday: weekday, meal_type: meal_type)
      entry&.destroy!

      respond_to do |format|
        format.turbo_stream { render_turbo_slot(weekday, meal_type, nil) }
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

    def run_upsert
      outcome = Menus::UpsertEntry.call(**upsert_args)
      assign_slot_vars(outcome)
    end

    def upsert_args
      {
        user: Current.user,
        menu: @menu,
        weekday: menu_entry_params[:weekday],
        meal_type: menu_entry_params[:meal_type],
        recipe_id: menu_entry_params[:recipe_id],
        freeform_text: menu_entry_params[:freeform_text]
      }
    end

    def assign_slot_vars(outcome)
      @weekday = Integer(menu_entry_params[:weekday])
      @meal_type = menu_entry_params[:meal_type].to_s
      @entry = outcome == :cleared ? nil : find_saved_entry
    end

    def find_saved_entry
      @menu.menu_entries.find_by!(weekday: @weekday, meal_type: @meal_type)
    end

    def assign_invalid_entry(error)
      @weekday = Integer(menu_entry_params[:weekday])
      @meal_type = menu_entry_params[:meal_type].to_s
      @entry = invalid_entry_from(error)
    end

    def invalid_entry_from(error)
      return error.record if error.record.is_a?(MenuEntry)

      @menu.menu_entries.find_by(weekday: @weekday, meal_type: @meal_type)
    end

    def respond_after_upsert(status: nil)
      respond_to do |format|
        format.turbo_stream { render_turbo_slot(@weekday, @meal_type, @entry, status) }
        format.html { redirect_slot_html(status) }
      end
    end

    def render_turbo_slot(weekday, meal_type, entry, status = nil)
      stream = turbo_stream.replace(
        slot_frame_id(@menu, weekday, meal_type),
        partial: "menus/slot",
        locals: { menu: @menu, weekday: weekday, meal_type: meal_type, entry: entry }
      )
      return render(turbo_stream: stream) if status.blank?

      render turbo_stream: stream, status: status
    end

    def redirect_slot_html(status)
      if status
        redirect_to edit_menu_path(@menu), alert: t("menus.entries.flash.could_not_save")
      else
        redirect_to edit_menu_path(@menu)
      end
    end
  end
end
