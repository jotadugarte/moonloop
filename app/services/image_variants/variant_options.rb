# frozen_string_literal: true

module ImageVariants
  class VariantOptions
    def self.for(variant_name)
      { format: :webp, resize_to_limit: ResizeToLimit.for(variant_name) }
    end
  end
end
