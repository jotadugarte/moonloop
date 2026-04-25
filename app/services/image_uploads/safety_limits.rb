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
      Result.new(errors: validation_errors(blob))
    end

    def self.validation_errors(blob)
      [ validate_byte_size(blob), validate_max_dimension(blob) ].compact
    end
    private_class_method :validation_errors

    def self.validate_byte_size(blob)
      :too_large if blob.byte_size.to_i > MAX_BYTES
    end
    private_class_method :validate_byte_size

    def self.validate_max_dimension(blob)
      :too_many_pixels if max_dimension_px(blob) > MAX_DIMENSION_PX
    end
    private_class_method :validate_max_dimension

    def self.max_dimension_px(blob)
      metadata = blob.metadata || {}
      width = metadata["width"].to_i
      height = metadata["height"].to_i

      [ width, height ].max
    end
    private_class_method :max_dimension_px
  end
end
