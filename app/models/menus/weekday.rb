module Menus
  class Weekday
    attr_reader :value

    def initialize(raw)
      @value = self.class.coerce!(raw)
    end

    def self.coerce!(raw)
      raise ArgumentError, "weekday is required" if raw.nil?

      value = Integer(raw)
      raise ArgumentError, "weekday must be 0..6" unless (0..6).cover?(value)

      value
    end
  end
end
