require "rails_helper"

RSpec.describe UserHabit, type: :model do
  let(:user) { create(:user) }
  let(:category) { create(:habit_category, user: user) }

  def build_habit(**attrs)
    build(
      :user_habit,
      {
        user: user,
        habit_category: category,
        name: "Test Habit",
        active: true
      }.merge(attrs)
    )
  end

  describe "frequency representation" do
    # [REQ-HAB-005]
    it "accepts daily with empty params" do
      habit = build_habit(frequency_type: "daily", frequency_params: {}, activation_date: nil)
      expect(habit).to be_valid
    end

    # [REQ-HAB-005]
    it "requires weekdays for weekdays frequency" do
      habit = build_habit(frequency_type: "weekdays", frequency_params: {}, activation_date: nil)
      expect(habit).not_to be_valid
      expect(habit.errors[:frequency_params]).not_to be_empty
    end

    # [REQ-HAB-005]
    it "requires interval and activation_date for every_x_days" do
      habit = build_habit(frequency_type: "every_x_days", frequency_params: { "interval" => 0 }, activation_date: nil)
      expect(habit).not_to be_valid
      expect(habit.errors[:frequency_params]).not_to be_empty
      expect(habit.errors[:activation_date]).not_to be_empty
    end

    # [REQ-HAB-005]
    it "requires activation_date for monthly" do
      habit = build_habit(frequency_type: "monthly", frequency_params: {}, activation_date: nil)
      expect(habit).not_to be_valid
      expect(habit.errors[:activation_date]).not_to be_empty
    end

    # [REQ-HAB-005]
    it "rejects weekly frequency type (use weekdays with a single day instead)" do
      habit = build_habit(frequency_type: "weekly", frequency_params: {}, activation_date: nil)
      expect(habit).not_to be_valid
      expect(habit.errors[:frequency_type]).not_to be_empty
    end
  end

  describe "monthly schedule semantics (end-of-month clamp)" do
    # [REQ-HAB-009]
    it "clamps to Feb 28 in non-leap years for Jan 31 anchor" do
      habit = build_habit(
        frequency_type: "monthly",
        frequency_params: {},
        activation_date: Date.new(2026, 1, 31)
      )

      expect(habit).to be_valid

      # After Jan 31, the next monthly occurrence should be Feb 28 for 2026.
      expect(habit.next_occurrence_after(Date.new(2026, 1, 31))).to eq(Date.new(2026, 2, 28))
    end
  end
end

