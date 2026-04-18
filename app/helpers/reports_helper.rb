# frozen_string_literal: true

module ReportsHelper
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

    line_or_dot = if coords.size == 1
      x, y = coords.first
      tag.circle(cx: format("%.1f", x), cy: format("%.1f", y), r: "4", fill: "#2563eb")
    else
      tag.polyline(
        fill: "none",
        stroke: "#2563eb",
        "stroke-width": "2",
        points: poly
      )
    end

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
        tag.text(
          x: pad_x,
          y: height - 2,
          fill: "#374151",
          "font-size": "10",
          "aria-hidden": true
        ) { chart_axis_start_label(series.first.logged_at, timezone) },
        tag.text(
          x: width - pad_x,
          y: height - 2,
          fill: "#374151",
          "font-size": "10",
          "text-anchor": "end",
          "aria-hidden": true
        ) { chart_axis_end_label(series.last.logged_at, timezone) }
      ])
    end
  end

  def reports_fulfillment_cell(stats)
    return tag.span("—", class: "reports-fulfillment-emdash") if stats.nil?

    if stats.due_count.zero?
      return tag.span(t("reports.show.fulfillment_no_due_days"), class: "reports-fulfillment-na")
    end

    pct = stats.percentage
    pct_s = pct.nil? ? "—" : "#{pct}%"

    t(
      "reports.show.fulfillment_cell",
      done: stats.done_count,
      due: stats.due_count,
      pct: pct_s
    )
  end

  private

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
