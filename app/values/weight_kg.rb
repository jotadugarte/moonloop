WeightKg = Data.define(:value) do
  def self.invalid_argument_error?(error)
    error.is_a?(ArgumentError) && error.message.start_with?("WeightKg must be 20–500")
  end

  def initialize(value:)
    v = BigDecimal(value.to_s)
    raise ArgumentError, "WeightKg must be 20–500, got #{v}" unless (20..500).cover?(v)
    super(value: v)
  end
end
