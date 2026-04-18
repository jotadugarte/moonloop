# frozen_string_literal: true

# REQ-RPT-001 — fulfillment; REQ-RPT-002 — streaks; REQ-RPT-003 — weight chart (single page /informes).
class ReportsController < ApplicationController
  def show
    result = Reports::ShowPage.call(user: Current.user, fecha_param: params[:fecha])
    if result.redirect_alert
      redirect_to informes_path, alert: result.redirect_alert
      return
    end

    result.assigns.each { |key, value| instance_variable_set("@#{key}", value) }
  end
end
