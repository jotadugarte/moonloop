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

  describe 'activation_date immutability when completions exist' do
    # [REQ-HAB-005]
    it 'allows changing activation_date when there are no completions' do
      habit = create(:user_habit,
        frequency_type: "every_x_days",
        frequency_params: { "interval" => 2 },
        activation_date: Date.new(2026, 1, 1))

      habit.update!(activation_date: Date.new(2026, 2, 1))

      expect(habit.reload.activation_date).to eq(Date.new(2026, 2, 1))
    end

    # [REQ-HAB-005]
    it 'rejects changing activation_date when any completion exists' do
      habit = create(:user_habit,
        frequency_type: "every_x_days",
        frequency_params: { "interval" => 2 },
        activation_date: Date.new(2026, 1, 1))
      create(:habit_completion, user_habit: habit, completed_on: Date.new(2026, 4, 1))

      expect(habit.update(activation_date: Date.new(2026, 3, 1))).to be(false)
      expect(habit.errors[:activation_date]).to include(
        I18n.t("activerecord.errors.models.user_habit.attributes.activation_date.locked_when_completions_exist")
      )
    end

    # [REQ-HAB-005]
    it 'allows changing activation_date again after all completions are removed' do
      habit = create(:user_habit,
        frequency_type: "every_x_days",
        frequency_params: { "interval" => 2 },
        activation_date: Date.new(2026, 1, 1))
      completion = create(:habit_completion, user_habit: habit, completed_on: Date.new(2026, 4, 1))
      completion.destroy!

      habit.update!(activation_date: Date.new(2026, 3, 15))

      expect(habit.reload.activation_date).to eq(Date.new(2026, 3, 15))
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
