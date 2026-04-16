# frozen_string_literal: true

module Habits
  # Maps legacy `frequency_type: "weekly"` rows to a single 0..6 weekday index (REQ-HAB-005).
  # Unit-tested; behavior is **duplicated** inside
  # `db/migrate/20260416203000_migrate_weekly_user_habits_to_weekdays.rb` (nested WdayResolver)
  # so that migration does not depend on app autoload. If rules change, update both places.
  class LegacyWeeklyWeekdayResolver
    Result = Struct.new(:wday, :used_fallback, keyword_init: true)

    def self.call(params, activation_date)
      new(params, activation_date).send(:resolve)
    end

    def initialize(params, activation_date)
      @params = params.is_a?(Hash) ? params : {}
      @activation_date = activation_date
    end

    private_class_method :new

    private

    def resolve
      wday = wday_from_weekdays_array
      return ok(wday) unless wday.nil?

      wday = wday_from_weekday_param
      return ok(wday) unless wday.nil?

      wday = wday_from_activation
      return ok(wday) unless wday.nil?

      Result.new(wday: 0, used_fallback: true)
    end

    def ok(wday)
      Result.new(wday: wday, used_fallback: false)
    end

    def wday_from_weekdays_array
      raw = @params["weekdays"] || @params[:weekdays]
      return nil unless raw.is_a?(Array)

      raw.each do |v|
        i = coerce_day_index(v)
        return i unless i.nil?
      end
      nil
    end

    def wday_from_weekday_param
      single = @params["weekday"] || @params[:weekday]
      return nil if single.blank?

      coerce_day_index(single)
    end

    def wday_from_activation
      return nil unless @activation_date.respond_to?(:wday)
      return nil if @activation_date.blank?

      @activation_date.wday
    end

    def coerce_day_index(value)
      return value if value.is_a?(Integer) && value.between?(0, 6)

      i = Integer(value, exception: false)
      return i if i.is_a?(Integer) && i.between?(0, 6)

      nil
    end
  end
end
