require 'rails_helper'

RSpec.describe UserHabit, type: :model do
  describe 'associations' do
    # [REQ-HAB-004]
    it { should belong_to(:user) }
    # [REQ-HAB-004]
    it { should belong_to(:habit_category) }
    # [REQ-HAB-004]
    it { should belong_to(:global_habit_template).optional }
  end

  describe 'validations' do
    subject { build(:user_habit) }

    # [REQ-HAB-004]
    it { should validate_presence_of(:name) }
  end

  describe 'normalization' do
    # [REQ-HAB-004]
    it 'derives name_normalized from name (strip + downcase)' do
      habit = build(:user_habit, name: "  Agua  ", name_normalized: "")
      expect(habit).to be_valid
      expect(habit.name_normalized).to eq("agua")
    end
  end

  describe 'name uniqueness among active habits' do
    # [REQ-HAB-006]
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
