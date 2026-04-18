# frozen_string_literal: true

module Habits
  # Returns whether +user_habit+ is scheduled on +local_date+ (civil date in the user's calendar).
  # Inactive habits are never due. See SPEC: "Scheduling — due-day resolution (Mi Día)".
  class DueOnDate
    # +schedule_only:+ when true, evaluates frequency rules as if the habit were active (REQ-RPT-001:
    # fulfillment for inactive habits that still have completions in the reporting window). Mi Día keeps
    # the default +false+ (inactive habits are never due in-product).
    def self.due_on?(user_habit, local_date, schedule_only: false)
      new(user_habit: user_habit, local_date: local_date, schedule_only: schedule_only).due_on?
    end

    def initialize(user_habit:, local_date:, schedule_only: false)
      @user_habit = user_habit
      @local_date = local_date
      @schedule_only = schedule_only
    end

    def due_on?
      return false unless @local_date.is_a?(Date)
      unless @schedule_only
        return false unless @user_habit.active?
      end

      case @user_habit.frequency_type
      when "daily"
        daily_due?
      when "weekdays"
        weekdays_due?
      when "every_x_days"
        every_x_days_due?
      when "monthly"
        monthly_due?
      else
        false
      end
    end

    private

    def daily_due?
      start = effective_start_date
      return false if @local_date < start

      true
    end

    def weekdays_due?
      weekdays = normalized_weekdays
      return false if weekdays.empty?

      start = effective_start_date
      first = first_weekday_on_or_after(start, weekdays)
      return false if @local_date < first

      weekdays.include?(@local_date.wday)
    end

    def every_x_days_due?
      act = @user_habit.activation_date
      return false if act.blank?
      return false if @local_date < act

      interval = interval_from_params
      return false if interval.nil? || interval < 1

      ((@local_date - act).to_i % interval).zero?
    end

    def monthly_due?
      act = @user_habit.activation_date
      return false if act.blank?

      scheduled = monthly_scheduled_date_for(@local_date.year, @local_date.month)
      scheduled == @local_date && @local_date >= act
    end

    def effective_start_date
      if @user_habit.activation_date.present?
        @user_habit.activation_date
      else
        zone = @user_habit.user&.timezone
        raise ArgumentError, "User timezone required for habits without activation_date" if zone.blank?

        @user_habit.created_at.in_time_zone(zone).to_date
      end
    end

    def normalized_weekdays
      raw = @user_habit.frequency_params.is_a?(Hash) ? @user_habit.frequency_params["weekdays"] : nil
      return [] unless raw.is_a?(Array)

      raw.select { |v| v.is_a?(Integer) && v.between?(0, 6) }
    end

    def first_weekday_on_or_after(start_date, weekdays)
      0.upto(6) do |offset|
        d = start_date + offset
        return d if weekdays.include?(d.wday)
      end
      start_date
    end

    def interval_from_params
      raw = @user_habit.frequency_params.is_a?(Hash) ? @user_habit.frequency_params["interval"] : nil
      raw.is_a?(Integer) ? raw : nil
    end

    def monthly_scheduled_date_for(year, month)
      anchor_day = @user_habit.activation_date.day
      last_day = Date.new(year, month, -1).day
      day = [ anchor_day, last_day ].min
      Date.new(year, month, day)
    end
  end
end
