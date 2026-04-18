HeightCm = Data.define(:value) do
  def self.invalid_argument_error?(error)
    error.is_a?(ArgumentError) && error.message.start_with?("HeightCm must be 50–300")
  end

  def initialize(value:)
    v = Integer(value)
    raise ArgumentError, "HeightCm must be 50–300, got #{v}" unless (50..300).cover?(v)
    super(value: v)
  end
end
