# frozen_string_literal: true

module ImageVariants
  # Memoized probe: true only when ruby-vips loads (native libvips present).
  class Available
    def self.call
      return @call_result if defined?(@call_result)

      @call_result = libvips_loadable?
    end

    def self.libvips_loadable?
      require "vips"
      true
    rescue LoadError
      false
    end
    private_class_method :libvips_loadable?
  end
end
