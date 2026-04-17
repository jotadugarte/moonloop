# frozen_string_literal: true

class WeightLogsController < ApplicationController
  before_action :set_weight_log, only: %i[confirm_destroy destroy]

  def new
    @weight_log = weight_log_for_new
  end

  def create
    logged_at = resolve_logged_at_for_create
    return if performed?

    LogWeightService.new(
      user: Current.user,
      weight_kg: weight_log_params[:weight_kg],
      logged_at: logged_at
    ).call
    redirect_to profile_path, notice: t("weight_logs.flash.created")
  rescue ActiveRecord::RecordInvalid => e
    @weight_log =
      if e.record.is_a?(WeightLog)
        e.record
      else
        weight_log_for_rescue(logged_at: logged_at)
      end
    if e.record.is_a?(User)
      @weight_log.errors.add(:base, t("weight_logs.errors.user_stats_update_failed"))
    end
    render :new, status: :unprocessable_content
  rescue ArgumentError => e
    @weight_log = weight_log_for_rescue(logged_at: logged_at)
    if e.message.match?(/WeightKg/i)
      @weight_log.errors.add(:weight_kg, e.message)
    else
      @weight_log.errors.add(:base, e.message)
    end
    render :new, status: :unprocessable_content
  end

  def confirm_destroy
  end

  def destroy
    WeightLogs::DestroyLog.call(weight_log: @weight_log)
    redirect_to profile_path, notice: t("weight_logs.flash.destroyed")
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

  def resolve_logged_at_for_create
    raw = weight_log_params[:logged_at].to_s
    return Time.current if raw.blank?

    parsed =
      begin
        Time.use_zone(Current.user.timezone) { Time.zone.parse(raw) }
      rescue ArgumentError
        nil
      end

    if parsed.nil?
      @weight_log = weight_log_for_rescue(logged_at: Time.current)
      @weight_log.errors.add(:logged_at, :invalid)
      render :new, status: :unprocessable_content
      return nil
    end

    parsed
  end

end
