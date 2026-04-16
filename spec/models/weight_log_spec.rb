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
