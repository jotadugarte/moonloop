# frozen_string_literal: true

module ImageUploads
  class SafetyLimits
    MAX_BYTES = 25.megabytes
    MAX_DIMENSION_PX = 8000

    Result = Struct.new(:errors, keyword_init: true) do
      def rejected?
        errors.any?
      end
    end

    def self.validate(blob)
      errors = []

      errors << :too_large if blob.byte_size.to_i > MAX_BYTES
      errors << :too_many_pixels if max_dimension_px(blob) > MAX_DIMENSION_PX

      Result.new(errors: errors)
    end

    def self.max_dimension_px(blob)
      metadata = blob.metadata || {}
      width = metadata["width"].to_i
      height = metadata["height"].to_i

      [ width, height ].max
    end
    private_class_method :max_dimension_px
  end
end
