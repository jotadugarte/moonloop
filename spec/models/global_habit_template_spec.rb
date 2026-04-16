require 'rails_helper'

# REQ-HABITS-001: Global habit templates have stable codes and i18n-backed labels.
RSpec.describe GlobalHabitTemplate, type: :model do
  describe 'validations' do
    subject { build(:global_habit_template) }

    it { should validate_presence_of(:code) }
    it { should validate_uniqueness_of(:code).ignoring_case_sensitivity }
  end
end

