# frozen_string_literal: true

require "rails_helper"

RSpec.describe WeightLogs::ReconcileUserCurrentStats do
  let(:user) { create(:user, height_cm: 180, timezone: "Etc/UTC") }

  describe ".call" do
    # [REQ-WGT-002]
    context "when the user has no weight_logs" do
      it "clears current_weight_kg and current_bmi" do
        user.update!(current_weight_kg: 80.0, current_bmi: 24.69)

        described_class.call(user: user)

        user.reload
        expect(user.current_weight_kg).to be_nil
        expect(user.current_bmi).to be_nil
      end
    end

    # [REQ-WGT-002]
    context "when the user has one weight_log" do
      it "sets current stats from that log" do
        log = create(
          :weight_log,
          user: user,
          weight_kg: 82.5,
          height_cm: 180,
          logged_at: 2.days.ago
        )

        described_class.call(user: user)

        user.reload
        expect(user.current_weight_kg).to eq(log.weight_kg)
        expect(user.current_bmi).to eq(log.bmi)
      end
    end

    # [REQ-WGT-002]
    context "when the user has multiple logs with different logged_at" do
      it "uses the row with the greatest logged_at" do
        create(:weight_log, user: user, weight_kg: 70.0, height_cm: 180, logged_at: 5.days.ago)
        newer = create(:weight_log, user: user, weight_kg: 75.0, height_cm: 180, logged_at: 1.day.ago)

        described_class.call(user: user)

        user.reload
        expect(user.current_weight_kg).to eq(newer.weight_kg)
        expect(user.current_bmi).to eq(newer.bmi)
      end
    end

    # [REQ-WGT-002]
    context "when two logs share the same logged_at" do
      it "uses the row with the greater id" do
        travel_to Time.utc(2026, 4, 17, 12, 0, 0) do
          t = 3.days.ago.change(usec: 0)
          first = create(:weight_log, user: user, weight_kg: 70.0, height_cm: 180, logged_at: t)
          second = create(:weight_log, user: user, weight_kg: 71.0, height_cm: 180, logged_at: t)

          expect(second.id).to be > first.id

          described_class.call(user: user)

          user.reload
          expect(user.current_weight_kg).to eq(second.weight_kg)
          expect(user.current_bmi).to eq(second.bmi)
        end
      end
    end
  end
end
