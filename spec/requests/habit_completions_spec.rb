# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Habit completions", type: :request do
  let(:user) { create(:user, password: "Password123!", timezone: "Etc/UTC") }

  before do
    post sign_in_path, params: { email: user.email, password: "Password123!" }
  end

  def post_completion!(habit, completed_on:, status:, day_progress: :omit)
    h = {
      user_habit_id: habit.id,
      completed_on: completed_on,
      status: status
    }
    h[:day_progress] = day_progress unless day_progress == :omit
    post habit_completions_path, params: { habit_completion: h }
  end

  # [REQ-DAY-002]
  it "creates a done completion for today" do
    travel_to Time.utc(2026, 4, 16, 12, 0, 0) do
      category = create(:habit_category, user: user)
      habit = create(:user_habit,
        user: user,
        habit_category: category,
        frequency_type: "daily",
        activation_date: Date.new(2026, 1, 1))

      post_completion!(habit, completed_on: "2026-04-16", status: "done")

      expect(response).to redirect_to(my_day_path)
      expect(flash[:notice]).to eq(I18n.t("habit_completions.flash.saved"))
      expect(HabitCompletion.find_by(user_habit: habit, completed_on: Date.new(2026, 4, 16))&.status).to eq("done")
    end
  end

  # [REQ-DAY-002]
  it "updates status from done to failed" do
    travel_to Time.utc(2026, 4, 16, 12, 0, 0) do
      category = create(:habit_category, user: user)
      habit = create(:user_habit,
        user: user,
        habit_category: category,
        frequency_type: "daily",
        activation_date: Date.new(2026, 1, 1))
      create(:habit_completion, user_habit: habit, completed_on: Date.new(2026, 4, 16), status: "done")

      post_completion!(habit, completed_on: "2026-04-16", status: "failed")

      expect(HabitCompletion.find_by(user_habit: habit, completed_on: Date.new(2026, 4, 16))&.status).to eq("failed")
    end
  end

  # [REQ-DAY-002]
  it "clears a completion" do
    travel_to Time.utc(2026, 4, 16, 12, 0, 0) do
      category = create(:habit_category, user: user)
      habit = create(:user_habit,
        user: user,
        habit_category: category,
        frequency_type: "daily",
        activation_date: Date.new(2026, 1, 1))
      completion = create(:habit_completion, user_habit: habit, completed_on: Date.new(2026, 4, 16), status: "done")

      delete habit_completion_path(completion)

      expect(response).to redirect_to(my_day_path)
      expect(flash[:notice]).to eq(I18n.t("habit_completions.flash.cleared"))
      expect(HabitCompletion.find_by(id: completion.id)).to be_nil
    end
  end

  # [REQ-DAY-002]
  it "rejects a future calendar date" do
    travel_to Time.utc(2026, 4, 16, 12, 0, 0) do
      category = create(:habit_category, user: user)
      habit = create(:user_habit,
        user: user,
        habit_category: category,
        frequency_type: "daily",
        activation_date: Date.new(2026, 1, 1))

      post_completion!(habit, completed_on: "2026-04-17", status: "done")

      expect(response).to redirect_to(my_day_path)
      expect(flash[:alert]).to eq(I18n.t("habit_completions.flash.future_date"))
      expect(HabitCompletion.count).to eq(0)
    end
  end

  # [REQ-DAY-002]
  it "rejects when the habit is not due on that date" do
    travel_to Time.utc(2026, 4, 16, 12, 0, 0) do
      category = create(:habit_category, user: user)
      habit = create(:user_habit,
        user: user,
        habit_category: category,
        name: "Solo martes",
        frequency_type: "weekdays",
        frequency_params: { "weekdays" => [ 2 ] },
        activation_date: Date.new(2026, 1, 1))

      post_completion!(habit, completed_on: "2026-04-16", status: "done")

      expect(flash[:alert]).to eq(I18n.t("habit_completions.flash.not_due"))
      expect(HabitCompletion.count).to eq(0)
    end
  end

  # [REQ-DAY-003]
  it "records a completion for a past local date" do
    travel_to Time.utc(2026, 4, 16, 12, 0, 0) do
      category = create(:habit_category, user: user)
      habit = create(:user_habit,
        user: user,
        habit_category: category,
        frequency_type: "daily",
        activation_date: Date.new(2026, 1, 1))

      post_completion!(habit, completed_on: "2026-04-10", status: "done")

      expect(response).to redirect_to(my_day_path(fecha: "2026-04-10"))
      expect(flash[:notice]).to eq(I18n.t("habit_completions.flash.saved"))
      expect(HabitCompletion.find_by(user_habit: habit, completed_on: Date.new(2026, 4, 10))&.status).to eq("done")
    end
  end

  # [REQ-DAY-002]
  it "rejects when the habit is inactive" do
    travel_to Time.utc(2026, 4, 16, 12, 0, 0) do
      category = create(:habit_category, user: user)
      habit = create(:user_habit,
        user: user,
        habit_category: category,
        frequency_type: "daily",
        activation_date: Date.new(2026, 1, 1),
        active: false)

      post_completion!(habit, completed_on: "2026-04-16", status: "done")

      expect(flash[:alert]).to eq(I18n.t("habit_completions.flash.inactive"))
      expect(HabitCompletion.count).to eq(0)
    end
  end

  # [REQ-DAY-005]
  it "persists day_progress and syncs status when the target is met" do
    travel_to Time.utc(2026, 4, 16, 12, 0, 0) do
      category = create(:habit_category, user: user)
      habit = create(:user_habit,
        user: user,
        habit_category: category,
        frequency_type: "daily",
        activation_date: Date.new(2026, 1, 1),
        habit_metric_kind: "count",
        daily_target: 4)

      post_completion!(habit, completed_on: "2026-04-16", status: "done", day_progress: "4")

      expect(response).to redirect_to(my_day_path)
      expect(flash[:notice]).to eq(I18n.t("habit_completions.flash.saved"))
      row = HabitCompletion.find_by!(user_habit: habit, completed_on: Date.new(2026, 4, 16))
      expect(row.day_progress).to eq(4)
      expect(row.status).to eq("done")
    end
  end
end
