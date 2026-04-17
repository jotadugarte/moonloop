module Menus
  class MealType
    KEYS = %w[desayuno almuerzo cena merienda].freeze

    attr_reader :key

    def initialize(raw)
      @key = self.class.coerce!(raw)
    end

    def self.coerce!(raw)
      raise ArgumentError, "meal_type is required" if raw.nil?

      key = raw.to_s.strip.downcase
      raise ArgumentError, "invalid meal_type: #{raw.inspect}" unless KEYS.include?(key)

      key
    end

    def to_s
      key
    end
  end
end
