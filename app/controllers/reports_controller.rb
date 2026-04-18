# frozen_string_literal: true

# REQ-RPT-001 — fulfillment; REQ-RPT-002 — streaks; REQ-RPT-003 — weight chart (single page /informes).
class ReportsController < ApplicationController
  def show
    zone = Time.find_zone!(Current.user.timezone)
    today = zone.today
    @max_date = today

    resolved = resolve_local_date(params[:fecha])
    if resolved.nil? && params[:fecha].present?
      redirect_to informes_path, alert: t("reports.flash.invalid_date")
      return
    end

    @local_date = resolved || today

    if @local_date > today
      redirect_to informes_path, alert: t("reports.flash.future_date")
      return
    end

    bounds = Reports::CalendarPeriodBounds.call(timezone: Current.user.timezone, local_date: @local_date)
    @week_range = bounds.week_range
    @month_range = bounds.month_range

    habits = Current.user.user_habits.includes(:habit_category).to_a
    combined_from = [ @week_range.begin, @month_range.begin ].min
    combined_to = [ @week_range.end, @month_range.end ].max
    @completions_by_habit = batch_completions(habits, combined_from..combined_to)

    @fulfillment_rows = build_fulfillment_rows(habits)
    @streak_rows = build_streak_rows(habits)
    @weight_series = WeightLogs::ChartSeries.call(user: Current.user).to_a
  end

  private

  def resolve_local_date(raw)
    return if raw.blank?

    Date.iso8601(raw.to_s)
  rescue ArgumentError
    nil
  end

  def batch_completions(habits, range)
    return {} if habits.empty?

    HabitCompletion
      .where(user_habit_id: habits.map(&:id), completed_on: range)
      .group_by(&:user_habit_id)
      .transform_values { |rows| rows.index_by(&:completed_on) }
  end

  def build_fulfillment_rows(habits)
    habits.sort_by { |h| [ h.habit_category.name.downcase, h.name.downcase ] }.filter_map do |habit|
      full = @completions_by_habit[habit.id] || {}
      week_idx = full.select { |d, _| (@week_range.begin..@week_range.end).cover?(d) }
      month_idx = full.select { |d, _| (@month_range.begin..@month_range.end).cover?(d) }

      week_stats = Habits::FulfillmentForPeriod.call(
        user_habit: habit,
        range: @week_range,
        completions_by_date: week_idx
      )
      month_stats = Habits::FulfillmentForPeriod.call(
        user_habit: habit,
        range: @month_range,
        completions_by_date: month_idx
      )

      next if week_stats.nil? && month_stats.nil?

      { habit: habit, week_stats: week_stats, month_stats: month_stats }
    end
  end

  def build_streak_rows(habits)
    return [] if habits.empty?

    from = habits.map { Habits::Streak.lower_bound_for(_1) }.min
    by_habit = HabitCompletion
      .where(user_habit_id: habits.map(&:id), completed_on: from..@local_date)
      .group_by(&:user_habit_id)
      .transform_values { |rows| rows.index_by(&:completed_on) }

    habits.sort_by { |h| [ h.habit_category.name.downcase, h.name.downcase ] }.map do |habit|
      idx = by_habit[habit.id] || {}
      {
        habit: habit,
        current: Habits::ReportCurrentStreak.call(
          user_habit: habit,
          as_of: @local_date,
          completions_by_date: idx
        ),
        longest: Habits::LongestStreak.call(
          user_habit: habit,
          through_date: @local_date,
          completions_by_date: idx
        )
      }
    end
  end
end
