require 'rails_helper'

RSpec.describe LogWeightService do
  let(:user) { create(:user, height_cm: 180) }

  describe '#call' do
    # [REQ-PROF-002, REQ-WGT-001]
    it 'creates a WeightLog and updates User current stats' do
      expect {
        LogWeightService.new(user: user, weight_kg: 80.5).call
      }.to change(WeightLog, :count).by(1)

      log = WeightLog.last
      expect(log.user).to eq(user)
      expect(log.weight_kg).to eq(80.5)
      expect(log.height_cm).to eq(180) # Snapshotted

      # (80.5 / 1.8**2).round(2)
      expect(log.bmi).to eq(24.85)

      expect(user.reload.current_weight_kg).to eq(80.5)
      expect(user.current_bmi).to eq(24.85)
    end

    # [REQ-WGT-001]
    it 'raises an ArgumentError if weight_kg is out of domain bounds' do
      expect {
        LogWeightService.new(user: user, weight_kg: 10.0).call
      }.to raise_error(ArgumentError, /WeightKg must be 20/)
    end

    # [REQ-PROF-002, REQ-WGT-001]
    it 'wraps the creation and update in a database transaction' do
      # If the User update fails, the WeightLog should rollback to maintain integrity.
      allow(user).to receive(:update!).and_raise(ActiveRecord::RecordInvalid)

      expect {
        begin
          LogWeightService.new(user: user, weight_kg: 80.5).call
        rescue ActiveRecord::RecordInvalid
        end
      }.not_to change(WeightLog, :count)
    end
  end
end
