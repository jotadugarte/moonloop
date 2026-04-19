# frozen_string_literal: true

module MyDayHelper
  def my_day_metric_progress_label(habit, completion)
    current = completion&.day_progress.to_i
    target = habit.daily_target.to_i
    case habit.habit_metric_kind
    when "duration_min"
      t("my_day.show.metric_progress_duration", current: current, target: target)
    when "count"
      t("my_day.show.metric_progress_count", current: current, target: target)
    else
      ""
    end
  end

  def my_day_metric_next_progress(habit, completion)
    p = completion&.day_progress.to_i
    [p + 1, HabitCompletion::DAY_PROGRESS_MAX].min
  end

  def my_day_metric_increment_disabled?(habit, completion)
    completion&.day_progress.to_i >= HabitCompletion::DAY_PROGRESS_MAX
  end
end
