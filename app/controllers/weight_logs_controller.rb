# frozen_string_literal: true

class WeightLogsController < ApplicationController
  before_action :set_weight_log, only: %i[confirm_destroy destroy]

  def index
    page = WeightLogs::HistoryPage.call(
      scope: Current.user.weight_logs.ordered_for_history,
      page_param: params[:page]
    )
    @weight_logs = page.records
    @page = page.page
    @total_pages = page.total_pages
  end

  def new
    @weight_log = weight_log_for_new
  end

  def create
    parsed = WeightLogs::LoggedAtParamParser.new(
      user: Current.user,
      raw: weight_log_params[:logged_at]
    ).call
    unless parsed.success
      render_invalid_logged_at
      return
    end

    persist_weight_entry(parsed.time)
  rescue ActiveRecord::RecordInvalid => e
    handle_record_invalid(e, logged_at: parsed.time)
  rescue ArgumentError => e
    handle_domain_argument_error(e, logged_at: parsed.time)
  end

  def confirm_destroy
  end

  def destroy
    WeightLogs::DestroyLog.call(weight_log: @weight_log)
    redirect_to weight_logs_path, notice: t("weight_logs.flash.destroyed")
  end

  private

  def set_weight_log
    @weight_log = Current.user.weight_logs.find(params[:id])
  end

  def weight_log_params
    params.fetch(:weight_log, {}).permit(:weight_kg, :logged_at)
  end

  def weight_log_for_new
    Current.user.weight_logs.new(
      height_cm: Current.user.height_cm,
      logged_at: Time.current
    )
  end

  def weight_log_for_rescue(logged_at:)
    Current.user.weight_logs.new(
      weight_kg: weight_log_params[:weight_kg],
      height_cm: Current.user.height_cm,
      logged_at: logged_at
    )
  end

  def render_invalid_logged_at
    @weight_log = weight_log_for_rescue(logged_at: Time.current)
    @weight_log.errors.add(:logged_at, :invalid)
    render :new, status: :unprocessable_content
  end

  # After a successful save, send users to the profile so "current weight" matches the latest reading in context.
  def persist_weight_entry(logged_at)
    LogWeightService.new(
      user: Current.user,
      weight_kg: weight_log_params[:weight_kg],
      logged_at: logged_at
    ).call
    redirect_to profile_path, notice: t("weight_logs.flash.created")
  end

  def handle_record_invalid(error, logged_at:)
    @weight_log =
      if error.record.is_a?(WeightLog)
        error.record
      else
        weight_log_for_rescue(logged_at: logged_at)
      end
    if error.record.is_a?(User)
      @weight_log.errors.add(:base, t("weight_logs.errors.user_stats_update_failed"))
    end
    render :new, status: :unprocessable_content
  end

  def handle_domain_argument_error(error, logged_at:)
    @weight_log = weight_log_for_rescue(logged_at: logged_at)
    if WeightKg.invalid_argument_error?(error)
      @weight_log.errors.add(:weight_kg, error.message)
    elsif HeightCm.invalid_argument_error?(error)
      @weight_log.errors.add(:base, error.message)
    else
      @weight_log.errors.add(:base, error.message)
    end
    render :new, status: :unprocessable_content
  end
end
