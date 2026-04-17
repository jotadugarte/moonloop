# frozen_string_literal: true

require "rails_helper"

RSpec.describe WeightLogs::DestroyLog do
  let(:user) { create(:user, height_cm: 180, timezone: "Etc/UTC") }

  describe ".call" do
    # [REQ-WGT-002] [REQ-WGT-003]
    it "destroys the weight log and reconciles the user's current stats" do
      log = create(:weight_log, user: user, weight_kg: 70.0, height_cm: 180)
      WeightLogs::ReconcileUserCurrentStats.call(user: user)
      user.reload
      expect(user.current_weight_kg).to eq(70.0)

      expect {
        described_class.call(weight_log: log)
      }.to change(WeightLog, :count).by(-1)

      expect(WeightLog.exists?(log.id)).to be false
      user.reload
      expect(user.current_weight_kg).to be_nil
      expect(user.current_bmi).to be_nil
    end
  end
end
