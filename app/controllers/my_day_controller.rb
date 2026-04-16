# frozen_string_literal: true

class MyDayController < ApplicationController
  def show
    zone = Time.find_zone!(Current.user.timezone)
    @local_date = zone.today
    @due_habits = Habits::DueHabitsForDay.call(user: Current.user, local_date: @local_date)
  end
end
