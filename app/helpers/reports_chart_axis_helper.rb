# frozen_string_literal: true

# Shared axis/tick helpers for Reports charts.
# [REQ-RPT-003, REQ-WGT-004]
module ReportsChartAxisHelper
  private

  def pad_x_legend_inset
    8
  end

  def weight_axis_ticks(w_min, w_max)
    if (w_max - w_min).abs < 0.01
      [ w_min ]
    else
      mid = (w_min + w_max) / 2.0
      [ w_min, mid, w_max ].uniq.sort
    end
  end

  def axis_label_tag(x, y, anchor)
    opts = {
      x: x,
      y: y,
      class: "reports-weight-chart__axis",
      "font-size": "10",
      "aria-hidden": true
    }
    opts["text-anchor"] = "end" if anchor == "end"

    tag.text(**opts) { yield }
  end

  def chart_axis_start_label(time_utc, timezone)
    Time.use_zone(timezone) do
      l(time_utc.in_time_zone, format: :reports_chart_axis)
    end
  end

  def chart_axis_end_label(time_utc, timezone)
    Time.use_zone(timezone) do
      l(time_utc.in_time_zone, format: :reports_chart_axis)
    end
  end
end
