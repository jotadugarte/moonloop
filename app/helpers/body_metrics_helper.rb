# frozen_string_literal: true

# Shared display of canonical kg/cm using the viewer's `body_unit_system`.
# [REQ-PROF-003, REQ-WGT-004]
module BodyMetricsHelper
  def format_body_weight(user, weight_kg)
    case user.body_unit_system
    when "imperial_us"
      lb = BodyMetrics.kg_to_lb_for_display(weight_kg)
      "#{number_with_precision(lb, precision: 1, strip_insignificant_zeros: false)} #{t('body_metrics.unit_lb')}"
    else
      "#{number_with_precision(weight_kg, precision: 2, strip_insignificant_zeros: true)} #{t('body_metrics.unit_kg')}"
    end
  end

  def format_body_height_snapshot(user, height_cm)
    case user.body_unit_system
    when "imperial_us"
      ft, inch = BodyMetrics.cm_to_ft_in(height_cm)
      t("body_metrics.height_ft_in", feet: ft, inches: inch)
    else
      "#{height_cm} #{t('body_metrics.unit_cm')}"
    end
  end

  def aria_for_weight_log_entry(weight_log, summary_id)
    if weight_log.errors[:weight_kg].present? || weight_log.errors[:base].present?
      { invalid: true, describedby: summary_id }
    else
      {}
    end
  end
end
