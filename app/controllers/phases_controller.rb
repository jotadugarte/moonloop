# frozen_string_literal: true

class PhasesController < ApplicationController
  def show
    @user = Current.user
    @week_index = Phases::WeekNumber.today_for(@user)
    @active_menu = Phases::ResolveActiveMenu.call(user: @user, week_index: @week_index)
    @assignments = @user.phase_assignments.includes(:menu).order(:start_week)
  end

  def update
    @user = Current.user
    if @user.update(phase_params)
      redirect_to phase_path, notice: t("phases.flash.anchor_updated")
    else
      @week_index = Phases::WeekNumber.today_for(@user)
      @active_menu = Phases::ResolveActiveMenu.call(user: @user, week_index: @week_index)
      @assignments = @user.phase_assignments.includes(:menu).order(:start_week)
      render :show, status: :unprocessable_entity
    end
  end

  private

  def phase_params
    params.require(:user).permit(:phase_one_starts_on)
  end
end
