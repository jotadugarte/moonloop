require 'rails_helper'

# REQ-HABITS-003: User habits support templates + personal habits, activation, and unique active names.
RSpec.describe UserHabit, type: :model do
  describe 'associations' do
    it { should belong_to(:user) }
    it { should belong_to(:habit_category) }
    it { should belong_to(:global_habit_template).optional }
  end

  describe 'validations' do
    subject { build(:user_habit) }

    it { should validate_presence_of(:name) }
    it { should validate_presence_of(:name_normalized) }
    it { should validate_presence_of(:active) }
  end

  describe 'name uniqueness among active habits' do
    it 'rejects a second active habit with same name ignoring case and whitespace' do
      user = create(:user)
      category = HabitCategory.create!(user: user, name: 'Salud Física', name_normalized: 'salud física')

      UserHabit.create!(
        user: user,
        habit_category: category,
        name: 'Agua',
        name_normalized: 'agua',
        active: true
      )

      dupe = UserHabit.new(
        user: user,
        habit_category: category,
        name: ' agua ',
        name_normalized: 'agua',
        active: true
      )

      expect(dupe).not_to be_valid
      expect(dupe.errors[:name]).not_to be_empty
    end
  end
end

