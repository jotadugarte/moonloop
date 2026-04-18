# frozen_string_literal: true

module Reports
  # REQ-RPT-001: Inclusive local date ranges for reporting — ISO week (Mon–Sun) and civil month.
  # +local_date+ must be the user's civil calendar date; +timezone+ is validated but civil math uses +local_date+ directly.
  class CalendarPeriodBounds
    Result = Struct.new(:week_range, :month_range, keyword_init: true)

    def self.call(timezone:, local_date:)
      new(timezone: timezone, local_date: local_date).call
    end

    def initialize(timezone:, local_date:)
      @timezone = timezone
      @local_date = local_date
    end

    def call
      raise ArgumentError, "local_date must be a Date" unless @local_date.is_a?(Date)

      zone = Time.find_zone(@timezone)
      raise ArgumentError, "timezone must be a valid IANA identifier" if zone.nil?

      week = monday_sunday_range(@local_date)
      month = @local_date.beginning_of_month..@local_date.end_of_month

      Result.new(week_range: week, month_range: month)
    end

    private

    def monday_sunday_range(local_date)
      monday = local_date - (local_date.cwday - 1)
      monday..(monday + 6)
    end
  end
end
