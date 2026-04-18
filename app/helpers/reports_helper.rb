# frozen_string_literal: true

module ReportsHelper
  include ReportsChartHelper

  def reports_fulfillment_cell(stats)
    placeholder = t("reports.show.fulfillment_placeholder")
    return tag.span(placeholder, class: "reports-fulfillment-emdash") if stats.nil?

    if stats.due_count.zero?
      return tag.span(t("reports.show.fulfillment_no_due_days"), class: "reports-fulfillment-na")
    end

    pct = stats.percentage
    pct_s = pct.nil? ? placeholder : t("reports.show.fulfillment_pct", value: pct)

    t(
      "reports.show.fulfillment_cell",
      done: stats.done_count,
      due: stats.due_count,
      pct: pct_s
    )
  end
end
