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
  end
end
