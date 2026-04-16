HeightCm = Data.define(:value) do
  def initialize(value:)
    v = Integer(value)
    raise ArgumentError, "HeightCm must be 50–300, got #{v}" unless (50..300).cover?(v)
    super(value: v)
  end
end
