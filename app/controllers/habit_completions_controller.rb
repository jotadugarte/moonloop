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
    result = record_completion(habit, local_date, permitted)

    redirect_after_result(result, day: local_date)
  end

  def habit_completion_params
    params.require(:habit_completion).permit(:user_habit_id, :completed_on, :status, :day_progress)
  end

  def find_habit(user_habit_id)
    Current.user.user_habits.find_by(id: user_habit_id)
  end

  def find_completion_for_current_user
    HabitCompletion.joins(:user_habit).where(user_habits: { user_id: Current.user.id }).find_by(id: params[:id])
  end

  def record_completion(habit, local_date, permitted)
    kwargs = {
      user: Current.user,
      user_habit: habit,
      local_date: local_date,
      status: permitted[:status].to_s
    }
    if permitted.key?(:day_progress)
      raw = permitted[:day_progress]
      kwargs[:day_progress] =
        if raw.nil? || raw.to_s.strip.empty?
          0
        else
          Integer(raw)
        end
    end
    Habits::RecordCompletion.call(**kwargs)
  rescue ArgumentError, TypeError
    :invalid_record
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
    path = habit_completion_redirect_path(result, opts)
    level, key = habit_completion_create_flash(result)
    redirect_to path, level => t(key)
  end

  def redirect_after_destroy_result(result, day: nil)
    opts = my_day_redirect_options(day)
    path = habit_completion_destroy_redirect_path(result, opts)
    level, key = habit_completion_destroy_flash(result)
    redirect_to path, level => t(key)
  end

  def habit_completion_redirect_path(result, opts)
    return my_day_path if %i[not_owner not_found].include?(result)
    return my_day_path if result == :future_date

    my_day_path(opts)
  end

  def habit_completion_create_flash(result)
    case result
    when :ok
      [ :notice, "habit_completions.flash.saved" ]
    when :not_owner, :not_found
      [ :alert, "habit_completions.flash.not_found" ]
    when :inactive
      [ :alert, "habit_completions.flash.inactive" ]
    when :future_date
      [ :alert, "habit_completions.flash.future_date" ]
    when :not_due
      [ :alert, "habit_completions.flash.not_due" ]
    when :invalid_status
      [ :alert, "habit_completions.flash.invalid_status" ]
    when :invalid_record
      [ :alert, "habit_completions.flash.could_not_save" ]
    else
      [ :alert, "habit_completions.flash.could_not_save" ]
    end
  end

  def habit_completion_destroy_redirect_path(result, opts)
    return my_day_path if %i[not_owner not_found].include?(result)

    my_day_path(opts)
  end

  def habit_completion_destroy_flash(result)
    case result
    when :ok
      [ :notice, "habit_completions.flash.cleared" ]
    when :not_owner, :not_found
      [ :alert, "habit_completions.flash.not_found" ]
    when :inactive
      [ :alert, "habit_completions.flash.inactive" ]
    else
      [ :alert, "habit_completions.flash.could_not_save" ]
    end
  end
end
