# frozen_string_literal: true

class HabitCompletionsController < ApplicationController
  def create
    process_create
  rescue ActionController::ParameterMissing
    redirect_to my_day_path, alert: t("habit_completions.flash.invalid_request")
  rescue ArgumentError, TypeError
    redirect_to my_day_path, alert: t("habit_completions.flash.invalid_date")
  end

  def destroy
    completion = find_completion_for_current_user
    unless completion
      redirect_to my_day_path, alert: t("habit_completions.flash.not_found")
      return
    end

    day = completion.completed_on
    result = Habits::ClearCompletion.call(user: Current.user, habit_completion: completion)

    redirect_after_destroy_result(result, day: day)
  end

  private

  def process_create
    permitted = habit_completion_params
    habit = find_habit(permitted[:user_habit_id])
    return not_found_redirect unless habit

    local_date = Date.iso8601(permitted[:completed_on].to_s)
    result = record_completion(habit, local_date, permitted[:status].to_s)

    redirect_after_result(result, day: local_date)
  end

  def habit_completion_params
    params.require(:habit_completion).permit(:user_habit_id, :completed_on, :status)
  end

  def find_habit(user_habit_id)
    Current.user.user_habits.find_by(id: user_habit_id)
  end

  def find_completion_for_current_user
    HabitCompletion.joins(:user_habit).where(user_habits: { user_id: Current.user.id }).find_by(id: params[:id])
  end

  def record_completion(habit, local_date, status)
    Habits::RecordCompletion.call(
      user: Current.user,
      user_habit: habit,
      local_date: local_date,
      status: status
    )
  end

  def not_found_redirect
    redirect_to my_day_path, alert: t("habit_completions.flash.not_found")
  end

  def my_day_redirect_options(day)
    return {} unless day.is_a?(Date)

    today = Time.find_zone!(Current.user.timezone).today
    return {} if day >= today

    { fecha: day.iso8601 }
  end

  def redirect_after_result(result, day: nil)
    opts = my_day_redirect_options(day)
    case result
    when :ok
      redirect_to my_day_path(opts), notice: t("habit_completions.flash.saved")
    when :not_owner, :not_found
      redirect_to my_day_path, alert: t("habit_completions.flash.not_found")
    when :inactive
      redirect_to my_day_path(opts), alert: t("habit_completions.flash.inactive")
    when :future_date
      redirect_to my_day_path, alert: t("habit_completions.flash.future_date")
    when :not_due
      redirect_to my_day_path(opts), alert: t("habit_completions.flash.not_due")
    when :invalid_status
      redirect_to my_day_path(opts), alert: t("habit_completions.flash.invalid_status")
    when :invalid_record
      redirect_to my_day_path(opts), alert: t("habit_completions.flash.could_not_save")
    else
      redirect_to my_day_path(opts), alert: t("habit_completions.flash.could_not_save")
    end
  end

  def redirect_after_destroy_result(result, day: nil)
    opts = my_day_redirect_options(day)
    case result
    when :ok
      redirect_to my_day_path(opts), notice: t("habit_completions.flash.cleared")
    when :not_owner, :not_found
      redirect_to my_day_path, alert: t("habit_completions.flash.not_found")
    when :inactive
      redirect_to my_day_path(opts), alert: t("habit_completions.flash.inactive")
    else
      redirect_to my_day_path(opts), alert: t("habit_completions.flash.could_not_save")
    end
  end
end
