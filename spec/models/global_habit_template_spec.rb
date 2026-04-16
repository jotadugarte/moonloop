require 'rails_helper'

RSpec.describe GlobalHabitTemplate, type: :model do
  describe 'validations' do
    subject { build(:global_habit_template) }

    # [REQ-HAB-001]
    it { should validate_presence_of(:code) }
    # [REQ-HAB-001]
    it { should validate_uniqueness_of(:code).ignoring_case_sensitivity }
  end
end

