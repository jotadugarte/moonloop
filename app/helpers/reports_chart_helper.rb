# frozen_string_literal: true

# Server-rendered weight sparkline (REQ-RPT-003). Geometry uses canonical +weight_kg+;
# Y-axis, legend, and point tooltips use +Current.user.body_unit_system+ via +BodyMetricsHelper+.
# [REQ-RPT-003, REQ-WGT-004]
module ReportsChartHelper
  include BodyMetricsHelper

  def reports_weight_chart_tag(series, timezone:, width: 400, height: 160)
    user = Current.user
    return tag.p(t("reports.show.weight_empty"), class: "reports-weight-empty") if series.blank?

    weights = series.map { |r| r.weight_kg.to_f }
    times = series.map { |r| r.logged_at.to_i }
    w_min, w_max = weights.minmax
    w_span = (w_max - w_min).abs < 0.01 ? 1.0 : (w_max - w_min)
    t_min, t_max = times.minmax
    t_span = t_max == t_min ? 1 : (t_max - t_min)

    pad_x_left = 56.0
    pad_x_right = 8.0
    pad_y = 22.0
    pad_y_bottom = 14.0
    inner_w = width - pad_x_left - pad_x_right
    inner_h = height - pad_y - pad_y_bottom

    coords = series.map do |r|
      tx = (r.logged_at.to_i - t_min).to_f / t_span
      wy = (r.weight_kg.to_f - w_min) / w_span
      x = pad_x_left + inner_w * tx
      y = pad_y + inner_h * (1 - wy)
      [ x, y ]
    end

    poly = coords.map { |x, y| "#{format('%.1f', x)},#{format('%.1f', y)}" }.join(" ")

    legend = chart_weight_legend_tag(user, width)
    y_axis = chart_y_axis_labels_tag(user, w_min, w_max, w_span, pad_y, inner_h)
    series_layer = chart_series_and_markers_tag(series, coords, poly, user, timezone)
    x_axis = chart_x_axis_labels_tag(series, timezone, pad_x_left, inner_w, height, pad_y_bottom)

    tag.svg(
      width: width,
      height: height,
      viewBox: "0 0 #{width} #{height}",
      role: "img",
      "aria-label": t("reports.show.weight_chart_aria"),
      class: "reports-weight-chart",
      xmlns: "http://www.w3.org/2000/svg"
    ) do
      safe_join([ legend, y_axis, series_layer, x_axis ].compact)
    end
  end

  private

  def chart_weight_legend_tag(user, width)
    unit = user.body_unit_system == "imperial_us" ? t("body_metrics.unit_lb") : t("body_metrics.unit_kg")
    text = t("reports.show.weight_chart_legend", unit: unit)
    tag.text(
      x: width - pad_x_legend_inset,
      y: 12,
      class: "reports-weight-chart__legend",
      "font-size": "10",
      "text-anchor": "end",
      "aria-hidden": true
    ) { text }
  end

  def pad_x_legend_inset
    8
  end

  def chart_y_axis_labels_tag(user, w_min, w_max, w_span, pad_y, inner_h)
    ticks = weight_axis_ticks(w_min, w_max)
    tag.g(class: "reports-weight-chart__y-axis", "aria-hidden": true) do
      safe_join(ticks.map do |w_kg|
        wy = (w_kg - w_min) / w_span
        y = pad_y + inner_h * (1 - wy)
        label = format_body_weight(user, BigDecimal(w_kg.to_s))
        tag.text(
          x: 4,
          y: y + 3,
          class: "reports-weight-chart__y-tick",
          "font-size": "9"
        ) { label }
      end)
    end
  end

  def weight_axis_ticks(w_min, w_max)
    if (w_max - w_min).abs < 0.01
      [ w_min ]
    else
      mid = (w_min + w_max) / 2.0
      [ w_min, mid, w_max ].uniq.sort
    end
  end

  def chart_series_and_markers_tag(series, coords, poly, user, timezone)
    line =
      if coords.size > 1
        tag.polyline(
          class: "reports-weight-chart__series",
          fill: "none",
          stroke: "#2563eb",
          "stroke-width": "2",
          points: poly
        )
      end

    markers = safe_join(
      series.each_with_index.map do |row, i|
        x, y = coords[i]
        tag.g(class: "reports-weight-chart__marker") do
          safe_join([
            tag.title { chart_point_tooltip(user, row, timezone) },
            tag.circle(
              cx: format("%.1f", x),
              cy: format("%.1f", y),
              r: (coords.size > 1 ? "3" : "4"),
              class: "reports-weight-chart__point",
              fill: "#2563eb"
            )
          ])
        end
      end
    )

    safe_join([ line, markers ].compact)
  end

  def chart_point_tooltip(user, row, timezone)
    t_local = row.logged_at.in_time_zone(timezone)
    "#{l(t_local, format: :reports_chart_axis)} — #{format_body_weight(user, row.weight_kg)}"
  end

  def chart_x_axis_labels_tag(series, timezone, pad_x_left, inner_w, height, pad_y_bottom)
    tag.g(class: "reports-weight-chart__x-axis", "aria-hidden": true) do
      safe_join([
        axis_label_tag(pad_x_left, height - 2, "start") { chart_axis_start_label(series.first.logged_at, timezone) },
        axis_label_tag(pad_x_left + inner_w, height - 2, "end") { chart_axis_end_label(series.last.logged_at, timezone) }
      ])
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
