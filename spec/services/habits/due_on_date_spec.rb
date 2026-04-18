# frozen_string_literal: true

require "rails_helper"

RSpec.describe Habits::DueOnDate do
  describe ".due_on?" do
    # [REQ-HAB-005]
    it "daily: is not due before activation_date when set" do
      habit = create(:user_habit,
        frequency_type: "daily",
        activation_date: Date.new(2026, 3, 10))

      expect(described_class.due_on?(habit, Date.new(2026, 3, 9))).to be(false)
      expect(described_class.due_on?(habit, Date.new(2026, 3, 10))).to be(true)
    end

    # [REQ-HAB-005]
    it "daily: without activation_date uses created_at in user timezone as effective start" do
      user = create(:user, timezone: "Etc/UTC")
      habit = create(:user_habit,
        user: user,
        frequency_type: "daily",
        activation_date: nil,
        created_at: Time.utc(2026, 6, 15, 8, 0, 0))

      expect(described_class.due_on?(habit, Date.new(2026, 6, 14))).to be(false)
      expect(described_class.due_on?(habit, Date.new(2026, 6, 15))).to be(true)
    end

    # [REQ-HAB-005]
    it "weekdays: first due is first listed weekday on or after activation_date" do
      habit = create(:user_habit,
        frequency_type: "weekdays",
        frequency_params: { "weekdays" => [ 1, 3 ] },
        activation_date: Date.new(2026, 1, 8))

      expect(described_class.due_on?(habit, Date.new(2026, 1, 8))).to be(false)
      expect(described_class.due_on?(habit, Date.new(2026, 1, 12))).to be(true)
    end

    # [REQ-HAB-005]
    it "weekdays: single weekday encodes once-per-week schedule" do
      habit = create(:user_habit,
        frequency_type: "weekdays",
        frequency_params: { "weekdays" => [ 2 ] },
        activation_date: Date.new(2026, 1, 1))

      expect(described_class.due_on?(habit, Date.new(2026, 1, 6))).to be(true)
      expect(described_class.due_on?(habit, Date.new(2026, 1, 7))).to be(false)
    end

    # [REQ-HAB-005]
    it "every_x_days: uses activation_date as day zero and interval from params" do
      habit = create(:user_habit,
        frequency_type: "every_x_days",
        frequency_params: { "interval" => 3 },
        activation_date: Date.new(2026, 2, 10))

      expect(described_class.due_on?(habit, Date.new(2026, 2, 9))).to be(false)
      expect(described_class.due_on?(habit, Date.new(2026, 2, 10))).to be(true)
      expect(described_class.due_on?(habit, Date.new(2026, 2, 11))).to be(false)
      expect(described_class.due_on?(habit, Date.new(2026, 2, 13))).to be(true)
    end

    # [REQ-HAB-005]
    it "monthly: clamps anchor day to last day of month" do
      habit = create(:user_habit,
        frequency_type: "monthly",
        activation_date: Date.new(2026, 1, 31))

      expect(described_class.due_on?(habit, Date.new(2026, 2, 28))).to be(true)
      expect(described_class.due_on?(habit, Date.new(2026, 2, 27))).to be(false)
    end

    # [REQ-HAB-005]
    it "monthly: no due date before activation_date even when that month's anchor day is earlier" do
      habit = create(:user_habit,
        frequency_type: "monthly",
        activation_date: Date.new(2026, 1, 20))

      expect(described_class.due_on?(habit, Date.new(2026, 1, 10))).to be(false)
      expect(described_class.due_on?(habit, Date.new(2026, 1, 20))).to be(true)
      expect(described_class.due_on?(habit, Date.new(2026, 2, 20))).to be(true)
    end

    # [REQ-DAY-001]
    it "returns false when habit is inactive" do
      habit = create(:user_habit,
        frequency_type: "daily",
        activation_date: Date.new(2026, 1, 1),
        active: false)

      expect(described_class.due_on?(habit, Date.new(2026, 6, 1))).to be(false)
    end

    # [REQ-RPT-001]
    it "when schedule_only is true, applies frequency rules even if the habit is inactive" do
      habit = create(:user_habit,
        frequency_type: "daily",
        activation_date: Date.new(2026, 1, 1),
        active: false)

      expect(described_class.due_on?(habit, Date.new(2026, 6, 1), schedule_only: true)).to be(true)
    end

    # [REQ-HAB-005]
    it "returns false when local_date is not a Date" do
      habit = create(:user_habit, frequency_type: "daily", activation_date: Date.new(2026, 1, 1))

      expect(described_class.due_on?(habit, "2026-01-01")).to be(false)
    end
  end
end
