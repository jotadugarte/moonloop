# frozen_string_literal: true

require "rails_helper"

RSpec.describe Phases::WeekNumber do
  let(:user) { create(:user, password: "Password123!", timezone: "America/New_York") }

  describe ".for_local_date" do
    # [REQ-MENU-003]
    it "returns nil when phase_one_starts_on is blank" do
      user.update!(phase_one_starts_on: nil)
      expect(described_class.for_local_date(user: user, local_date: Date.new(2026, 5, 1))).to be_nil
    end

    # [REQ-MENU-003]
    it "returns nil when the local date is before the anchor" do
      user.update!(phase_one_starts_on: Date.new(2026, 4, 10))
      expect(described_class.for_local_date(user: user, local_date: Date.new(2026, 4, 9))).to be_nil
    end

    # [REQ-MENU-003]
    it "returns 1 on the anchor date" do
      user.update!(phase_one_starts_on: Date.new(2026, 4, 10))
      expect(described_class.for_local_date(user: user, local_date: Date.new(2026, 4, 10))).to eq(1)
    end

    # [REQ-MENU-003]
    it "returns 1 for the first six days after the anchor" do
      user.update!(phase_one_starts_on: Date.new(2026, 4, 10))
      expect(described_class.for_local_date(user: user, local_date: Date.new(2026, 4, 16))).to eq(1)
    end

    # [REQ-MENU-003]
    it "returns 2 starting seven days after the anchor" do
      user.update!(phase_one_starts_on: Date.new(2026, 4, 10))
      expect(described_class.for_local_date(user: user, local_date: Date.new(2026, 4, 17))).to eq(2)
    end
  end

  describe ".today_for" do
    # [REQ-MENU-003]
    it "uses the user's IANA timezone to pick today's calendar date" do
      user.update!(phase_one_starts_on: Date.new(2026, 4, 14), timezone: "Pacific/Auckland")
      ak_time = ActiveSupport::TimeZone["Pacific/Auckland"].local(2026, 4, 21, 10, 0, 0)
      travel_to(ak_time) do
        expect(described_class.today_for(user.reload)).to eq(2)
      end
    end
  end
end
