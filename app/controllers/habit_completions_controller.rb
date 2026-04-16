# frozen_string_literal: true

class HabitCompletionsController < ApplicationController
  def create
    permitted = params.require(:habit_completion).permit(:user_habit_id, :completed_on, :status)
    habit = Current.user.user_habits.find_by(id: permitted[:user_habit_id])
    unless habit
      redirect_to my_day_path, alert: t("habit_completions.flash.not_found")
      return
    end

    local_date = Date.iso8601(permitted[:completed_on].to_s)
    status = permitted[:status].to_s

    result = Habits::RecordCompletion.call(
      user: Current.user,
      user_habit: habit,
      local_date: local_date,
      status: status
    )

    redirect_after_result(result)
  rescue ActionController::ParameterMissing
    redirect_to my_day_path, alert: t("habit_completions.flash.invalid_request")
  rescue ArgumentError, TypeError
    redirect_to my_day_path, alert: t("habit_completions.flash.invalid_date")
  end

  def destroy
    completion = HabitCompletion.joins(:user_habit).where(user_habits: { user_id: Current.user.id }).find_by(id: params[:id])
    unless completion
      redirect_to my_day_path, alert: t("habit_completions.flash.not_found")
      return
    end

    result = Habits::ClearCompletion.call(user: Current.user, habit_completion: completion)

    redirect_after_destroy_result(result)
  end

  private

  def redirect_after_result(result)
    case result
    when :ok
      redirect_to my_day_path, notice: t("habit_completions.flash.saved")
    when :not_owner, :not_found
      redirect_to my_day_path, alert: t("habit_completions.flash.not_found")
    when :inactive
      redirect_to my_day_path, alert: t("habit_completions.flash.inactive")
    when :future_date
      redirect_to my_day_path, alert: t("habit_completions.flash.future_date")
    when :not_due
      redirect_to my_day_path, alert: t("habit_completions.flash.not_due")
    when :invalid_status
      redirect_to my_day_path, alert: t("habit_completions.flash.invalid_status")
    when :invalid_record
      redirect_to my_day_path, alert: t("habit_completions.flash.could_not_save")
    else
      redirect_to my_day_path, alert: t("habit_completions.flash.could_not_save")
    end
  end

  def redirect_after_destroy_result(result)
    case result
    when :ok
      redirect_to my_day_path, notice: t("habit_completions.flash.cleared")
    when :not_owner, :not_found
      redirect_to my_day_path, alert: t("habit_completions.flash.not_found")
    when :inactive
      redirect_to my_day_path, alert: t("habit_completions.flash.inactive")
    else
      redirect_to my_day_path, alert: t("habit_completions.flash.could_not_save")
    end
  end
end
