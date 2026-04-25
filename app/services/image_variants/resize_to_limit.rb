# frozen_string_literal: true

module ImageVariants
  class ResizeToLimit
    MAX_DIMENSION_PX = 8000

    def self.for(variant_name)
      case variant_name.to_sym
      when :thumb
        [160, 160]
      when :list
        [640, MAX_DIMENSION_PX]
      when :detail
        [1200, MAX_DIMENSION_PX]
      else
        raise ArgumentError, "Unknown image variant: #{variant_name.inspect}"
      end
    end
  end
end

