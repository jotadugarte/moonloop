WeightKg = Data.define(:value) do
  def initialize(value:)
    v = BigDecimal(value.to_s)
    raise ArgumentError, "WeightKg must be 20–500, got #{v}" unless (20..500).cover?(v)
    super(value: v)
  end
end
