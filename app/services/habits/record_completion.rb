# frozen_string_literal: true

module Habits
  # Persists done/failed for a user-local calendar day (REQ-DAY-002, REQ-DAY-005).
  class RecordCompletion
    DAY_PROGRESS_UNSET = Object.new.freeze

    def self.call(user:, user_habit:, local_date:, status:, day_progress: DAY_PROGRESS_UNSET)
      new(
        user: user,
        user_habit: user_habit,
        local_date: local_date,
        status: status.to_s,
        day_progress: day_progress
      ).call
    end

    def initialize(user:, user_habit:, local_date:, status:, day_progress: DAY_PROGRESS_UNSET)
      @user = user
      @user_habit = user_habit
      @local_date = local_date
      @status = status
      @day_progress_param = day_progress
      @day_progress_unset = (day_progress == DAY_PROGRESS_UNSET)
    end

    def call
      return :not_owner unless @user_habit.user_id == @user.id
      return :inactive unless @user_habit.active?
      return :future_date if @local_date > user_local_today
      return :not_due unless DueOnDate.due_on?(@user_habit, @local_date)
      return :invalid_status unless HabitCompletion::STATUSES.include?(@status)

      completion = HabitCompletion.find_or_initialize_by(user_habit: @user_habit, completed_on: @local_date)
      apply_metric_rules!(completion)
      return :invalid_record unless completion.save

      mark_streak_counters_stale_if_retroactive!
      @user_habit.touch

      :ok
    end

    private

    def apply_metric_rules!(completion)
      if @user_habit.habit_metric_kind == "none"
        completion.day_progress = 0
        completion.status = @status
        completion.marked_failed_by_user = (@status == "failed")
        return
      end

      completion.day_progress = resolved_day_progress(completion)

      if @status == "failed"
        completion.status = "failed"
        completion.marked_failed_by_user = true
        return
      end

      completion.marked_failed_by_user = false
      completion.status =
        if completion.day_progress >= @user_habit.daily_target
          "done"
        else
          "failed"
        end
    end

    def resolved_day_progress(completion)
      if @day_progress_unset
        return 0 unless completion.persisted?

        completion.day_progress
      else
        @day_progress_param.to_i.clamp(0, HabitCompletion::DAY_PROGRESS_MAX)
      end
    end

    def user_local_today
      Time.find_zone!(@user.timezone).today
    end

    def mark_streak_counters_stale_if_retroactive!
      return unless @user_habit.respond_to?(:streak_counters_stale)
      return unless @local_date < user_local_today

      @user_habit.update!(streak_counters_stale: true)
    end
  end
end
