# frozen_string_literal: true

require "rails_helper"

RSpec.describe WeightLogs::HistoryPage do
  let(:user) { create(:user, height_cm: 180) }

  describe ".call" do
    # [REQ-WGT-003]
    it "returns up to PER_PAGE records and total_pages" do
      travel_to Time.utc(2026, 4, 17, 12, 0, 0) do
        31.times do |i|
          create(:weight_log, user: user, weight_kg: 70.0, height_cm: 180, logged_at: i.days.ago)
        end

        scope = user.weight_logs.ordered_for_history
        result = described_class.call(scope: scope, page_param: "1")

        expect(result.records.size).to eq(30)
        expect(result.page).to eq(1)
        expect(result.total_pages).to eq(2)

        page2 = described_class.call(scope: scope, page_param: "2")
        expect(page2.records.size).to eq(1)
        expect(page2.page).to eq(2)
      end
    end
  end
end
