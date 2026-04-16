require "rails_helper"

RSpec.describe Habits::LegacyWeeklyWeekdayResolver do
  describe ".call" do
    # [REQ-HAB-005]
    it "uses the first valid integer from frequency_params weekdays array" do
      result = described_class.call({ "weekdays" => [ 9, "2", 3 ] }, nil)
      expect(result.wday).to eq(2)
      expect(result.used_fallback).to be(false)
    end

    # [REQ-HAB-005]
    it "uses weekday key when weekdays array yields nothing valid" do
      result = described_class.call({ "weekdays" => [], "weekday" => 4 }, nil)
      expect(result.wday).to eq(4)
      expect(result.used_fallback).to be(false)
    end

    # [REQ-HAB-005]
    it "coerces string weekday to integer" do
      result = described_class.call({ "weekday" => "5" }, nil)
      expect(result.wday).to eq(5)
      expect(result.used_fallback).to be(false)
    end

    # [REQ-HAB-005]
    it "uses activation_date.wday when params do not specify a day" do
      date = Date.new(2026, 4, 16) # Thursday => 4
      result = described_class.call({}, date)
      expect(result.wday).to eq(4)
      expect(result.used_fallback).to be(false)
    end

    # [REQ-HAB-005]
    it "uses Sunday from activation without marking fallback" do
      date = Date.new(2026, 4, 12) # Sunday => 0
      result = described_class.call({}, date)
      expect(result.wday).to eq(0)
      expect(result.used_fallback).to be(false)
    end

    # [REQ-HAB-005]
    it "defaults to Sunday and flags fallback when nothing else applies" do
      result = described_class.call({}, nil)
      expect(result.wday).to eq(0)
      expect(result.used_fallback).to be(true)
    end

    # [REQ-HAB-005]
    it "treats non-hash params as empty" do
      result = described_class.call(nil, nil)
      expect(result.wday).to eq(0)
      expect(result.used_fallback).to be(true)
    end

    # [REQ-HAB-005]
    it "reads symbol keys in params" do
      result = described_class.call({ weekdays: [ 1 ] }, nil)
      expect(result.wday).to eq(1)
      expect(result.used_fallback).to be(false)
    end
  end
end
