# frozen_string_literal: true

require "rails_helper"

RSpec.describe WeightLogs::ChartSeries do
  describe ".call" do
    # [REQ-RPT-003]
    it "returns the user's logs ordered by logged_at ascending, then id ascending" do
      user = create(:user, height_cm: 180)
      other = create(:user, height_cm: 175)

      t_early = Time.utc(2026, 4, 10, 9, 0, 0)
      t_mid = Time.utc(2026, 4, 11, 9, 0, 0)
      t_late = Time.utc(2026, 4, 12, 9, 0, 0)

      log_b = create(:weight_log, user: user, weight_kg: 71.0, height_cm: 180, logged_at: t_late)
      log_a = create(:weight_log, user: user, weight_kg: 70.0, height_cm: 180, logged_at: t_early)
      log_c = create(:weight_log, user: user, weight_kg: 70.5, height_cm: 180, logged_at: t_mid)
      create(:weight_log, user: other, weight_kg: 99.0, height_cm: 175, logged_at: t_early)

      series = described_class.call(user: user).to_a

      expect(series.map(&:id)).to eq([ log_a.id, log_c.id, log_b.id ])
    end

    # [REQ-RPT-003]
    it "breaks ties on logged_at using id ascending" do
      user = create(:user, height_cm: 180)
      same = Time.utc(2026, 4, 10, 12, 0, 0)

      earlier_row = create(:weight_log, user: user, weight_kg: 70.0, height_cm: 180, logged_at: same)
      later_row = create(:weight_log, user: user, weight_kg: 71.0, height_cm: 180, logged_at: same)

      expect(earlier_row.id).to be < later_row.id

      series = described_class.call(user: user).to_a

      expect(series.map(&:id)).to eq([ earlier_row.id, later_row.id ])
    end

    # [REQ-RPT-003]
    it "projects only chart columns" do
      user = create(:user, height_cm: 180)
      create(:weight_log, user: user, weight_kg: 70.0, height_cm: 180, logged_at: Time.utc(2026, 4, 10, 12, 0, 0))

      row = described_class.call(user: user).sole

      expect(row.attributes.keys.sort).to eq(%w[bmi id logged_at weight_kg])
    end

    # [REQ-RPT-003]
    it "returns an empty relation when the user has no logs" do
      user = create(:user, height_cm: 180)

      expect(described_class.call(user: user)).to be_empty
    end
  end
end
