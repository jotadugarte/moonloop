# frozen_string_literal: true

class WeightLogsController < ApplicationController
  before_action :set_weight_log, only: %i[confirm_destroy destroy]

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
end
