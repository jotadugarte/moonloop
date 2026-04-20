# frozen_string_literal: true

module Habits
  class ProcessHabitReminderForUserHabit
    # status: Symbol to short-circuit #call, or nil when user + local_date are set
    ReminderProcessingContext = Struct.new(:status, :user, :local_date, keyword_init: true)

    def self.call(user_habit:)
      new(user_habit: user_habit).call
    end

    def initialize(user_habit:)
      @user_habit = user_habit
    end

    def call
      ctx = reminder_processing_context
      return ctx.status if ctx.status

      return :already_done if habit_done_on_local_date?(ctx.local_date)

      return :ok unless insert_reminder_event!(ctx.user, ctx.local_date)

      # [REQ-HAB-013]
      deliver_reminder_channels(ctx.user)
      :ok
    end

    private

    attr_reader :user_habit

    def reminder_processing_context
      return ReminderProcessingContext.new(status: :inactive) unless user_habit.active?
      return ReminderProcessingContext.new(status: :reminder_disabled) unless user_habit.reminder_enabled?

      user = user_habit.user
      timezone_name = user&.timezone
      return ReminderProcessingContext.new(status: :missing_timezone) if timezone_name.blank?

      tz = Time.find_zone(timezone_name)
      return ReminderProcessingContext.new(status: :invalid_timezone) unless tz

      local_date = tz.at(Time.current).to_date
      ReminderProcessingContext.new(status: nil, user: user, local_date: local_date)
    end

    def insert_reminder_event!(user, local_date)
      HabitReminderEvent.create!(user: user, user_habit: user_habit, local_date: local_date)
      true
    rescue ActiveRecord::RecordNotUnique
      false
    end

    def deliver_reminder_channels(user)
      if user_habit.reminder_email?
        HabitReminderMailer.notify(user: user, user_habit: user_habit).deliver_now
      end

      if user_habit.reminder_web_push?
        Habits::DeliverHabitReminderWebPush.call(user: user, user_habit: user_habit)
      end
    end

    def habit_done_on_local_date?(local_date)
      completion = user_habit.habit_completions.find_by(completed_on: local_date)
      Habits::Streak.habit_day_done?(user_habit: user_habit, completion: completion)
    end
  end
end
