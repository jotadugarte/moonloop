# frozen_string_literal: true

class MyDayController < ApplicationController
  def show
    zone = Time.find_zone!(Current.user.timezone)
    @local_date = zone.today
    @due_habits = Habits::DueHabitsForDay.call(user: Current.user, local_date: @local_date)
    habit_ids = @due_habits.map(&:id)
    @completions_by_habit_id = if habit_ids.empty?
      {}
    else
      HabitCompletion.where(user_habit_id: habit_ids, completed_on: @local_date).index_by(&:user_habit_id)
    end
  end
end
