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
    @weight_lb_display = nil
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

    if missing_weight_input?
      render_missing_weight(parsed.time)
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
    params.fetch(:weight_log, {}).permit(:weight_kg, :weight_lb, :logged_at)
  end

  def missing_weight_input?
    if Current.user.body_unit_system == "imperial_us"
      weight_log_params[:weight_lb].blank?
    else
      weight_log_params[:weight_kg].blank?
    end
  end

  def weight_kg_for_service
    if Current.user.body_unit_system == "imperial_us"
      BodyMetrics.lb_to_kg(BigDecimal(weight_log_params[:weight_lb].to_s)).to_f
    else
      weight_log_params[:weight_kg]
    end
  end

  def weight_log_for_new
    Current.user.weight_logs.new(
      height_cm: Current.user.height_cm,
      logged_at: Time.current
    )
  end

  def weight_log_for_rescue(logged_at:)
    attrs = {
      height_cm: Current.user.height_cm,
      logged_at: logged_at
    }
    attrs[:weight_kg] = Current.user.body_unit_system == "imperial_us" ? nil : weight_log_params[:weight_kg]
    Current.user.weight_logs.new(attrs)
  end

  def assign_weight_lb_display_for_form
    @weight_lb_display = Current.user.body_unit_system == "imperial_us" ? weight_log_params[:weight_lb] : nil
  end

  def render_missing_weight(logged_at)
    @weight_log = weight_log_for_rescue(logged_at: logged_at)
    @weight_log.errors.add(:base, I18n.t("weight_logs.errors.weight_blank"))
    assign_weight_lb_display_for_form
    render :new, status: :unprocessable_content
  end

  def render_invalid_logged_at
    @weight_log = weight_log_for_rescue(logged_at: Time.current)
    @weight_log.errors.add(:logged_at, :invalid)
    assign_weight_lb_display_for_form
    render :new, status: :unprocessable_content
  end

  # After a successful save, send users to the profile so "current weight" matches the latest reading in context.
  def persist_weight_entry(logged_at)
    LogWeightService.new(
      user: Current.user,
      weight_kg: weight_kg_for_service,
      logged_at: logged_at
    ).call
    redirect_to edit_profile_path, notice: t("weight_logs.flash.created")
  end

  def handle_record_invalid(error, logged_at:)
    assign_weight_lb_display_for_form
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
    assign_weight_lb_display_for_form
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
