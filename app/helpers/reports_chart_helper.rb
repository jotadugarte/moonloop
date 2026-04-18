# frozen_string_literal: true

module ReportsChartHelper
  # Server-rendered sparkline (REQ-RPT-003) — lightweight SVG polyline, no extra JS.
  def reports_weight_chart_tag(series, timezone:, width: 400, height: 160)
    return tag.p(t("reports.show.weight_empty"), class: "reports-weight-empty") if series.blank?

    weights = series.map { |r| r.weight_kg.to_f }
    times = series.map { |r| r.logged_at.to_i }
    w_min, w_max = weights.minmax
    w_span = (w_max - w_min).abs < 0.01 ? 1.0 : (w_max - w_min)
    t_min, t_max = times.minmax
    t_span = t_max == t_min ? 1 : (t_max - t_min)

    pad_x = 8.0
    pad_y = 8.0
    inner_w = width - (2 * pad_x)
    inner_h = height - (2 * pad_y)

    coords = series.map do |r|
      tx = (r.logged_at.to_i - t_min).to_f / t_span
      wy = (r.weight_kg.to_f - w_min) / w_span
      x = pad_x + inner_w * tx
      y = pad_y + inner_h * (1 - wy)
      [ x, y ]
    end

    poly = coords.map { |x, y| "#{format('%.1f', x)},#{format('%.1f', y)}" }.join(" ")

    line_or_dot = single_point_or_series(coords, poly)

    tag.svg(
      width: width,
      height: height,
      viewBox: "0 0 #{width} #{height}",
      role: "img",
      "aria-label": t("reports.show.weight_chart_aria"),
      class: "reports-weight-chart",
      xmlns: "http://www.w3.org/2000/svg"
    ) do
      safe_join([
        line_or_dot,
        axis_label_tag(pad_x, height - 2, "start") { chart_axis_start_label(series.first.logged_at, timezone) },
        axis_label_tag(width - pad_x, height - 2, "end") { chart_axis_end_label(series.last.logged_at, timezone) }
      ])
    end
  end

  private

  def single_point_or_series(coords, poly)
    if coords.size == 1
      x, y = coords.first
      tag.circle(cx: format("%.1f", x), cy: format("%.1f", y), r: "4", class: "reports-weight-chart__point")
    else
      tag.polyline(
        class: "reports-weight-chart__series",
        points: poly
      )
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
