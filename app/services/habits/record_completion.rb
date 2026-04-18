# frozen_string_literal: true

module Habits
  # Persists done/failed for a user-local calendar day (REQ-DAY-002).
  class RecordCompletion
    def self.call(user:, user_habit:, local_date:, status:)
      new(user: user, user_habit: user_habit, local_date: local_date, status: status.to_s).call
    end

    def initialize(user:, user_habit:, local_date:, status:)
      @user = user
      @user_habit = user_habit
      @local_date = local_date
      @status = status
    end

    def call
      return :not_owner unless @user_habit.user_id == @user.id
      return :inactive unless @user_habit.active?
      return :future_date if @local_date > user_local_today
      return :not_due unless DueOnDate.due_on?(@user_habit, @local_date)
      return :invalid_status unless HabitCompletion::STATUSES.include?(@status)

      completion = HabitCompletion.find_or_initialize_by(user_habit: @user_habit, completed_on: @local_date)
      completion.status = @status
      return :invalid_record unless completion.save

      # Busts +Habits::MiDayStreakPrefetch+ cache keys (see +UserHabit#cache_key_with_version+).
      @user_habit.touch

      :ok
    end

    private

    def user_local_today
      Time.find_zone!(@user.timezone).today
    end
  end
end
