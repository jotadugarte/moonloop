# frozen_string_literal: true

module WeightLogs
  # Parses datetime-local (or blank) into a Time in the user's zone. Used by WeightLogsController#create.
  class LoggedAtParamParser
    Result = Struct.new(:success, :time, keyword_init: true)

    def initialize(user:, raw:)
      @user = user
      @raw = raw.to_s
    end

    def call
      return Result.new(success: true, time: Time.current) if @raw.blank?

      parsed = parse_in_zone
      return Result.new(success: false, time: nil) if parsed.nil?

      Result.new(success: true, time: parsed)
    end

    private

    def parse_in_zone
      Time.use_zone(@user.timezone) { Time.zone.parse(@raw) }
    rescue ArgumentError
      nil
    end
  end
end
