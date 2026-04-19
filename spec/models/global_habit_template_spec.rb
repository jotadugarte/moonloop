require 'rails_helper'

RSpec.describe GlobalHabitTemplate, type: :model do
  describe 'validations' do
    subject { build(:global_habit_template) }

    # [REQ-HAB-001]
    it { should validate_presence_of(:code) }
    # [REQ-HAB-001]
    it { should validate_uniqueness_of(:code).ignoring_case_sensitivity }

    # [REQ-DAY-005]
    it "rejects invalid suggested_habit_metric_kind" do
      tpl = build(:global_habit_template, suggested_habit_metric_kind: "bogus")
      expect(tpl).not_to be_valid
      expect(tpl.errors[:suggested_habit_metric_kind]).to be_present
    end

    # [REQ-DAY-005]
    it "normalizes none templates to a daily target of 1" do
      tpl = create(:global_habit_template, suggested_habit_metric_kind: "none", suggested_daily_target: 9)
      expect(tpl.reload.suggested_daily_target).to eq(1)
    end
  end
end
