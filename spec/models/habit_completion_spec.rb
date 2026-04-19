# frozen_string_literal: true

require "rails_helper"

RSpec.describe HabitCompletion, type: :model do
  describe "associations" do
    # [REQ-DAY-002]
    it { is_expected.to belong_to(:user_habit) }
  end

  describe "validations" do
    subject { build(:habit_completion) }

    # [REQ-DAY-002]
    it { is_expected.to validate_presence_of(:completed_on) }
    # [REQ-DAY-002]
    it { is_expected.to validate_presence_of(:status) }
    # [REQ-DAY-002]
    it {
      is_expected.to validate_inclusion_of(:status).in_array(HabitCompletion::STATUSES)
    }

    describe "uniqueness of completed_on per user_habit" do
      # [REQ-DAY-002]
      it "rejects a second row for the same day" do
        habit = create(:user_habit)
        create(:habit_completion, user_habit: habit, completed_on: Date.new(2026, 4, 10), status: "done")
        dup = build(:habit_completion, user_habit: habit, completed_on: Date.new(2026, 4, 10), status: "failed")

        expect(dup).not_to be_valid
        expect(dup.errors[:completed_on]).to be_present
      end
    end

    describe "inactive user_habit" do
      # [REQ-DAY-002]
      it "is invalid on create" do
        habit = create(:user_habit, active: false)
        completion = build(:habit_completion, user_habit: habit)

        expect(completion).not_to be_valid
        expect(completion.errors[:base]).to include(
          I18n.t("activerecord.errors.models.habit_completion.attributes.base.user_habit_inactive")
        )
      end

      # [REQ-DAY-002]
      it "is invalid on update when the habit becomes inactive" do
        habit = create(:user_habit, active: true)
        completion = create(:habit_completion, user_habit: habit, completed_on: Date.new(2026, 4, 1))
        habit.update!(active: false)

        completion.status = "failed"

        expect(completion).not_to be_valid
        expect(completion.errors[:base]).to include(
          I18n.t("activerecord.errors.models.habit_completion.attributes.base.user_habit_inactive")
        )
      end
    end
  end

  describe "marked_failed_by_user" do
    # [REQ-DAY-005]
    it "defaults to false" do
      completion = create(:habit_completion)
      expect(completion.reload.marked_failed_by_user).to be(false)
    end
  end

  describe "day_progress" do
    # [REQ-DAY-005]
    it "defaults day_progress to 0" do
      completion = create(:habit_completion)
      expect(completion.reload.day_progress).to eq(0)
    end

    # [REQ-DAY-005]
    it "allows positive day_progress for count habits" do
      habit = create(:user_habit, habit_metric_kind: "count", daily_target: 5)
      completion = build(:habit_completion, user_habit: habit, day_progress: 3)
      expect(completion).to be_valid
    end

    # [REQ-DAY-005]
    it "rejects non-zero day_progress when habit metric is none" do
      habit = create(:user_habit, habit_metric_kind: "none")
      completion = build(:habit_completion, user_habit: habit, day_progress: 1)
      expect(completion).not_to be_valid
      expect(completion.errors[:day_progress]).to be_present
    end
  end
end
