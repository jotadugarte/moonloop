# frozen_string_literal: true

module Reports
  # REQ-RPT-001–003: assembles assigns for Informes. Streak rows use the same inactive visibility
  # rule as fulfillment (REQ-RPT-002 §4): an inactive habit appears only if it has at least one
  # completion in the union of the reference week and month (the combined window).
  class ShowPage
    Result = Struct.new(:redirect_alert, :assigns, keyword_init: true)

    def self.call(user:, fecha_param:)
      new(user: user, fecha_param: fecha_param).call
    end

    def initialize(user:, fecha_param:)
      @user = user
      @fecha_param = fecha_param
    end

    def call
      payload = build_payload
      return Result.new(redirect_alert: payload[:alert], assigns: nil) if payload[:alert]

      Result.new(redirect_alert: nil, assigns: payload[:assigns])
    end

    private

    def build_payload
      zone = Time.find_zone!(@user.timezone)
      today = zone.today
      resolved = resolve_local_date(@fecha_param)
      return { alert: I18n.t("reports.flash.invalid_date") } if resolved.nil? && @fecha_param.present?

      local_date = resolved || today
      return { alert: I18n.t("reports.flash.future_date") } if local_date > today

      bounds = CalendarPeriodBounds.call(timezone: @user.timezone, local_date: local_date)
      week_range = bounds.week_range
      month_range = bounds.month_range
      habits = @user.user_habits.includes(:habit_category).to_a

      combined_from = [ week_range.begin, month_range.begin ].min
      combined_to = [ week_range.end, month_range.end ].max
      completions_by_habit = completions_through_window(habits, week_range, month_range, local_date)

      {
        assigns: {
          max_date: today,
          local_date: local_date,
          week_range: week_range,
          month_range: month_range,
          fulfillment_rows: fulfillment_rows(habits, week_range, month_range, completions_by_habit),
          streak_rows: streak_rows(
            habits,
            local_date,
            today,
            combined_from,
            combined_to,
            completions_by_habit
          ),
          weight_series: WeightLogs::ChartSeries.call(user: @user).to_a
        }
      }
    end

    def resolve_local_date(raw)
      return if raw.blank?

      Date.iso8601(raw.to_s)
    rescue ArgumentError
      nil
    end

    def completions_through_window(habits, week_range, month_range, local_date)
      return {} if habits.empty?

      combined_from = [ week_range.begin, month_range.begin ].min
      combined_to = [ week_range.end, month_range.end ].max
      streak_from = habits.map { Habits::Streak.lower_bound_for(_1) }.min
      start_on = [ streak_from, combined_from ].min
      end_on = [ combined_to, local_date ].max

      HabitCompletion
        .where(user_habit_id: habits.map(&:id), completed_on: start_on..end_on)
        .group_by(&:user_habit_id)
        .transform_values { |rows| rows.index_by(&:completed_on) }
    end

    def fulfillment_rows(habits, week_range, month_range, completions_by_habit)
      habits.sort_by { |h| [ h.habit_category.name.downcase, h.name.downcase ] }.filter_map do |habit|
        full = completions_by_habit[habit.id] || {}
        week_idx = full.select { |d, _| (week_range.begin..week_range.end).cover?(d) }
        month_idx = full.select { |d, _| (month_range.begin..month_range.end).cover?(d) }

        week_stats = Habits::FulfillmentForPeriod.call(
          user_habit: habit,
          range: week_range,
          completions_by_date: week_idx
        )
        month_stats = Habits::FulfillmentForPeriod.call(
          user_habit: habit,
          range: month_range,
          completions_by_date: month_idx
        )

        next if week_stats.nil? && month_stats.nil?

        { habit: habit, week_stats: week_stats, month_stats: month_stats }
      end
    end

    def streak_rows(habits, local_date, today, combined_from, combined_to, completions_by_habit)
      return [] if habits.empty?

      window = combined_from..combined_to
      eligible = habits.select do |h|
        next true if h.active?

        idx = completions_by_habit[h.id]
        idx&.keys&.any? { |d| window.cover?(d) }
      end

      eligible.sort_by { |h| [ h.habit_category.name.downcase, h.name.downcase ] }.map do |habit|
        idx = completions_by_habit[habit.id] || {}
        if use_persisted_streak_counters?(habit, local_date: local_date, today: today)
          next({
            habit: habit,
            current: habit.current_streak_today,
            longest: habit.longest_streak_through_today
          })
        end

        {
          habit: habit,
          current: Habits::ReportCurrentStreak.call(
            user_habit: habit,
            as_of: local_date,
            completions_by_date: idx
          ),
          longest: Habits::LongestStreak.call(
            user_habit: habit,
            through_date: local_date,
            completions_by_date: idx
          )
        }
      end
    end

    def use_persisted_streak_counters?(habit, local_date:, today:)
      return false unless local_date == today
      return false unless habit.respond_to?(:streak_counters_stale)

      habit.streak_counters_stale == false && habit.streak_counters_as_of == today
    end
  end
end
