# frozen_string_literal: true

class MyDayController < ApplicationController
  def show
    zone = Time.find_zone!(Current.user.timezone)
    today = zone.today
    @max_date = today

    resolved = resolve_local_date(params[:fecha])
    if resolved.nil? && params[:fecha].present?
      redirect_to my_day_path, alert: t("my_day.flash.invalid_date")
      return
    end

    @local_date = resolved || today

    if @local_date > today
      redirect_to my_day_path, alert: t("my_day.flash.future_date_not_allowed")
      return
    end

    load_day_payload
  end

  private

  def load_day_payload
    @due_habits = Habits::DueHabitsForDay.call(user: Current.user, local_date: @local_date)
    habit_ids = @due_habits.map(&:id)
    @completions_by_habit_id = completions_for_day(habit_ids)
    @streak_by_habit_id = streaks_for_due_habits
  end

  def completions_for_day(habit_ids)
    return {} if habit_ids.empty?

    HabitCompletion.where(user_habit_id: habit_ids, completed_on: @local_date).index_by(&:user_habit_id)
  end

  def streak_completions_indexed_by_date
    lowers = @due_habits.map { |h| Habits::Streak.lower_bound_for(h) }
    from = lowers.min
    habit_ids = @due_habits.map(&:id)

    HabitCompletion
      .where(user_habit_id: habit_ids, completed_on: from..@local_date)
      .group_by(&:user_habit_id)
      .transform_values { |rows| rows.index_by(&:completed_on) }
  end

  def streaks_for_due_habits
    return {} if @due_habits.empty?

    by_habit = streak_completions_indexed_by_date

    @due_habits.each_with_object({}) do |habit, acc|
      acc[habit.id] = Habits::Streak.call(
        user_habit: habit,
        as_of: @local_date,
        completions_by_date: by_habit[habit.id] || {}
      )
    end
  end

  def resolve_local_date(raw)
    return if raw.blank?

    Date.iso8601(raw.to_s)
  rescue ArgumentError
    nil
  end
end
