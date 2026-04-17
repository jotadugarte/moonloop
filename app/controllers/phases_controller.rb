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
      redirect_options = { notice: t("phases.flash.anchor_updated") }
      if anchor_date_just_changed?(@user) && phase_start_more_than_three_local_days_away?(@user)
        redirect_options[:alert] = t("phases.flash.anchor_far_future_warning")
      end
      redirect_to phase_path, **redirect_options
    else
      @week_index = Phases::WeekNumber.today_for(@user)
      @active_menu = Phases::ResolveActiveMenu.call(user: @user, week_index: @week_index)
      @assignments = @user.phase_assignments.includes(:menu).order(:start_week)
      render :show, status: :unprocessable_entity
    end
  end

  def dismiss_reminder
    @user = Current.user
    tz = Time.find_zone(@user.timezone)
    local_today = tz&.today || Time.zone.today

    @user.update!(phase_reminder_dismissed_on: local_today)
    redirect_to phase_path, notice: t("phases.flash.reminder_dismissed")
  end

  private

  def anchor_date_just_changed?(user)
    user.previous_changes.key?("phase_one_starts_on")
  end

  def phase_start_more_than_three_local_days_away?(user)
    anchor = user.phase_one_starts_on
    return false if anchor.blank?

    tz = Time.find_zone(user.timezone)
    return false if tz.nil?

    local_today = tz.today
    (anchor - local_today).to_i > 3
  end

  def phase_params
    params.require(:user).permit(
      :phase_one_starts_on,
      :phase_reminder_in_app,
      :phase_reminder_email
    )
  end
end
