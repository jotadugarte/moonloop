# frozen_string_literal: true

class PhasesController < ApplicationController
  before_action :set_user
  before_action :load_phase_dashboard, only: [ :show ]

  def show
  end

  def update
    if @user.update(phase_params)
      redirect_after_phase_update
    else
      load_phase_dashboard
      render :show, status: :unprocessable_entity
    end
  end

  def repeat_last_assignment
    if Phases::RepeatLastPhaseAssignment.call(user: @user)
      redirect_to phase_path, notice: t("phases.flash.repeat_last_assignment_created")
    else
      redirect_to phase_path, alert: t("phases.flash.repeat_last_assignment_nothing_to_repeat")
    end
  end

  def dismiss_reminder
    tz = Time.find_zone(@user.timezone)
    local_today = tz&.today || Time.zone.today

    @user.update!(phase_reminder_dismissed_on: local_today)
    redirect_to phase_path, notice: t("phases.flash.reminder_dismissed")
  end

  private

  def set_user
    @user = Current.user
  end

  def load_phase_dashboard
    @week_index = Phases::WeekNumber.today_for(@user)
    @active_menu = Phases::ResolveActiveMenu.call(user: @user, week_index: @week_index)
    @assignments = @user.phase_assignments.includes(:menu).order(:start_week)
    @phase_start_in_app_reminder = Phases::PhaseStartInAppReminderVisible.call(user: @user)
    @plan_ended = Phases::PlanEnded.call(user: @user, week_index: @week_index)
  end

  def redirect_after_phase_update
    opts = { notice: t("phases.flash.anchor_updated") }
    opts[:alert] = t("phases.flash.anchor_far_future_warning") if anchor_far_future_warning?
    redirect_to phase_path, **opts
  end

  def anchor_far_future_warning?
    anchor_date_just_changed?(@user) && phase_start_more_than_three_local_days_away?(@user)
  end

  def anchor_date_just_changed?(user)
    user.previous_changes.key?("phase_one_starts_on")
  end

  def phase_start_more_than_three_local_days_away?(user)
    delta = phase_anchor_delta_days(user)
    delta.present? && delta > 3
  end

  def phase_anchor_delta_days(user)
    return nil unless phase_anchor_ready?(user)

    (user.phase_one_starts_on - phase_tz_today(user)).to_i
  end

  def phase_anchor_ready?(user)
    user.phase_one_starts_on.present? && Time.find_zone(user.timezone).present?
  end

  def phase_tz_today(user)
    Time.find_zone(user.timezone).today
  end

  def phase_params
    params.require(:user).permit(
      :phase_one_starts_on,
      :phase_reminder_in_app,
      :phase_reminder_email
    )
  end
end
