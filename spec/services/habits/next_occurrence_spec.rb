# frozen_string_literal: true

require "rails_helper"

RSpec.describe Habits::NextOccurrence do
  describe ".after" do
    # [REQ-HAB-009]
    it "returns the next listed weekday strictly after date for weekdays frequency" do
      user = create(:user, timezone: "Etc/UTC")
      habit = create(:user_habit,
        user: user,
        frequency_type: "weekdays",
        frequency_params: { "weekdays" => [ 2 ] },
        activation_date: Date.new(2026, 1, 1))

      # 2026-04-13 is Monday (wday 1); next Tuesday is 2026-04-14
      result = described_class.after(user_habit: habit, date: Date.new(2026, 4, 13))

      expect(result).to eq(Date.new(2026, 4, 14))
    end

    # [REQ-HAB-009]
    it "returns the next due day strictly after date for every_x_days" do
      user = create(:user, timezone: "Etc/UTC")
      habit = create(:user_habit,
        user: user,
        frequency_type: "every_x_days",
        frequency_params: { "interval" => 3 },
        activation_date: Date.new(2026, 4, 10))

      # Due on 10, 13, 16, … — first due strictly after 10 Apr is 13 Apr
      result = described_class.after(user_habit: habit, date: Date.new(2026, 4, 10))

      expect(result).to eq(Date.new(2026, 4, 13))
    end
  end
end
