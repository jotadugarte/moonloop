# frozen_string_literal: true

require "rails_helper"

RSpec.describe Reports::CalendarPeriodBounds do
  describe ".call" do
    # [REQ-RPT-001]
    it "returns Monday–Sunday week range and civil month range for a mid-week local date" do
      result = described_class.call(timezone: "Europe/Madrid", local_date: Date.new(2026, 4, 15))

      expect(result.week_range).to eq(Date.new(2026, 4, 13)..Date.new(2026, 4, 19))
      expect(result.month_range).to eq(Date.new(2026, 4, 1)..Date.new(2026, 4, 30))
    end

    # [REQ-RPT-001]
    it "anchors the week to Monday when the local date is a Sunday" do
      result = described_class.call(timezone: "America/New_York", local_date: Date.new(2026, 4, 19))

      expect(result.week_range).to eq(Date.new(2026, 4, 13)..Date.new(2026, 4, 19))
    end

    # [REQ-RPT-001]
    it "anchors the week to Monday when the local date is a Monday" do
      result = described_class.call(timezone: "Etc/UTC", local_date: Date.new(2026, 4, 13))

      expect(result.week_range).to eq(Date.new(2026, 4, 13)..Date.new(2026, 4, 19))
    end

    # [REQ-RPT-001]
    it "rejects an unknown IANA timezone" do
      expect do
        described_class.call(timezone: "Not/AZone", local_date: Date.new(2026, 4, 15))
      end.to raise_error(ArgumentError, /timezone/)
    end

    # [REQ-RPT-001]
    it "requires local_date to be a Date" do
      expect do
        described_class.call(timezone: "Europe/Madrid", local_date: "2026-04-15")
      end.to raise_error(ArgumentError, /local_date/)
    end
  end
end
