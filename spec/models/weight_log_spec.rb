require 'rails_helper'

RSpec.describe WeightLog, type: :model do
  describe 'Associations' do
    # [REQ-WGT-001]
    it { should belong_to(:user) }
  end

  describe 'Validations' do
    subject { build(:weight_log) }

    # [REQ-WGT-001]
    it { should validate_presence_of(:weight_kg) }
    # [REQ-WGT-001]
    it { should validate_presence_of(:height_cm) }
    # bmi is computed automatically, and tested below

    describe 'weight_kg range' do
      # [REQ-WGT-001]
      it 'is valid between 20 and 500' do
        log = build(:weight_log, weight_kg: 100)
        expect(log).to be_valid
      end

      # [REQ-WGT-001]
      it 'is invalid if below 20' do
        log = build(:weight_log, weight_kg: 19.9)
        expect(log).not_to be_valid
        expect(log.errors[:weight_kg]).to include(
          I18n.t("activerecord.errors.messages.greater_than_or_equal_to", count: 20)
        )
      end

      # [REQ-WGT-001]
      it 'is invalid if above 500' do
        log = build(:weight_log, weight_kg: 500.1)
        expect(log).not_to be_valid
        expect(log.errors[:weight_kg]).to include(
          I18n.t("activerecord.errors.messages.less_than_or_equal_to", count: 500)
        )
      end
    end
  end

  describe 'Immutability (attr_readonly)' do
    # [REQ-WGT-001]
    it 'prevents changing weight_kg and height_cm after creation' do
      log = create(:weight_log, weight_kg: 70, height_cm: 175)

      expect {
        log.weight_kg = 80
      }.to raise_error(ActiveRecord::ReadonlyAttributeError)

      expect {
        log.height_cm = 180
      }.to raise_error(ActiveRecord::ReadonlyAttributeError)
    end
  end

  describe 'logged_at' do
    # [REQ-WGT-001]
    it 'is required' do
      log = build(:weight_log, logged_at: nil)
      expect(log).not_to be_valid
      expect(log.errors[:logged_at]).to include(
        I18n.t("errors.messages.blank")
      )
    end

    # [REQ-WGT-001]
    it 'is invalid when strictly after now in the user timezone' do
      user = create(:user, timezone: "UTC")
      travel_to Time.utc(2026, 4, 17, 12, 0, 0) do
        log = build(:weight_log, user: user, logged_at: 1.hour.from_now)
        expect(log).not_to be_valid
        expect(log.errors[:logged_at]).to be_present
      end
    end

    # [REQ-WGT-001]
    it 'is valid when at or before now in the user timezone' do
      user = create(:user, timezone: "Europe/Madrid")
      Time.use_zone("Europe/Madrid") do
        travel_to Time.zone.parse("2026-04-17 14:00:00") do
          log = build(:weight_log, user: user, logged_at: Time.zone.now)
          expect(log).to be_valid
        end
      end
    end
  end

  describe '.ordered_for_history' do
    # [REQ-WGT-001]
    it 'orders by logged_at descending, then id descending' do
      user = create(:user)
      freeze_time = Time.utc(2026, 4, 17, 12, 0, 0)
      travel_to freeze_time do
        older = create(:weight_log, user: user, logged_at: 2.days.ago)
        newer = create(:weight_log, user: user, logged_at: 1.day.ago)
        tie_a = create(:weight_log, user: user, logged_at: 3.days.ago)
        tie_b = create(:weight_log, user: user, logged_at: 3.days.ago)

        expect(WeightLog.ordered_for_history.where(user_id: user.id).to_a).to eq(
          [ newer, older, tie_b, tie_a ]
        )
      end
    end
  end

  describe 'Callbacks' do
    describe '#compute_bmi' do
      # [REQ-WGT-001]
      it 'computes the BMI rounded to 2 decimals before validation' do
        log = build(:weight_log, weight_kg: 70.0, height_cm: 175, bmi: nil)

        # Action
        log.valid?

        # Verified computation 70 / (1.75 * 1.75) = 22.85714...
        expect(log.bmi).to eq(22.86)
      end
    end
  end
end
