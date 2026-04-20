# frozen_string_literal: true

require "rails_helper"

RSpec.describe "User habits update", type: :request do
  let(:user) { create(:user, password: "Password123!") }

  before do
    post sign_in_path, params: { email: user.email, password: "Password123!" }
  end

  # [REQ-RPT-002]
  it "marks streak counters stale when daily target changes" do
    category = create(:habit_category, user: user)
    habit = create(:user_habit,
      user: user,
      habit_category: category,
      name: "Agua",
      habit_metric_kind: "count",
      daily_target: 4,
      streak_counters_stale: false,
      streak_counters_as_of: Date.new(2026, 4, 20))

    patch user_habit_path(habit),
      params: {
        user_habit: {
          name: "Agua",
          habit_metric_kind: "count",
          daily_target: "9"
        }
      }

    expect(response).to redirect_to(user_habits_path)
    expect(habit.reload.daily_target).to eq(9)
    expect(habit.streak_counters_stale).to be(true)
  end

  # [REQ-DAY-005]
  it "updates daily target and metric kind" do
    category = create(:habit_category, user: user)
    habit = create(:user_habit,
      user: user,
      habit_category: category,
      name: "Agua",
      habit_metric_kind: "count",
      daily_target: 4)

    patch user_habit_path(habit),
      params: {
        user_habit: {
          name: "Agua",
          habit_metric_kind: "count",
          daily_target: "9"
        }
      }

    expect(response).to redirect_to(user_habits_path)
    expect(flash[:notice]).to eq(I18n.t("user_habits.flash.updated"))
    expect(habit.reload.daily_target).to eq(9)
  end
end
