# frozen_string_literal: true

require "rails_helper"

RSpec.describe WeightLogs::LoggedAtParamParser do
  let(:user) { create(:user, timezone: "Europe/Madrid") }

  describe "#call" do
    # [REQ-WGT-002]
    it "uses current time when raw is blank" do
      freeze_time = Time.utc(2026, 4, 17, 10, 0, 0)
      travel_to freeze_time do
        result = described_class.new(user: user, raw: "").call
        expect(result.success).to be true
        expect(result.time).to eq(freeze_time)
      end
    end

    # [REQ-WGT-002]
    it "parses a datetime-local string in the user zone" do
      result = described_class.new(user: user, raw: "2026-04-16T12:30").call
      expect(result.success).to be true
      expect(result.time).to be_a(Time)
    end

    # [REQ-WGT-002]
    it "returns failure for unparseable input" do
      result = described_class.new(user: user, raw: "not-a-date").call
      expect(result.success).to be false
      expect(result.time).to be_nil
    end
  end
end
