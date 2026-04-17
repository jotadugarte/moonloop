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

    @due_habits = Habits::DueHabitsForDay.call(user: Current.user, local_date: @local_date)
    habit_ids = @due_habits.map(&:id)
    @completions_by_habit_id = if habit_ids.empty?
      {}
    else
      HabitCompletion.where(user_habit_id: habit_ids, completed_on: @local_date).index_by(&:user_habit_id)
    end

    @streak_by_habit_id = @due_habits.each_with_object({}) do |habit, acc|
      acc[habit.id] = Habits::Streak.call(user_habit: habit, as_of: @local_date)
    end
  end

  private

  def resolve_local_date(raw)
    return if raw.blank?

    Date.iso8601(raw.to_s)
  rescue ArgumentError
    nil
  end
end
