IanaTimezone = Data.define(:value) do
  VALID_ZONES = ActiveSupport::TimeZone.all.map { |tz| tz.tzinfo.name }.to_set.freeze

  def initialize(value:)
    raise ArgumentError, "Invalid IANA timezone: #{value}" unless VALID_ZONES.include?(value)
    super(value: value)
  end
end
