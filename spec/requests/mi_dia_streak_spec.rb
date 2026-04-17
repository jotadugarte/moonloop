# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Mi Día streak display", type: :request do
  let(:user) { create(:user, password: "Password123!", timezone: "Etc/UTC") }

  before do
    post sign_in_path, params: { email: user.email, password: "Password123!" }
  end

  # [REQ-DAY-004]
  it "embeds current streak per habit for the viewed local day" do
    travel_to Time.utc(2026, 4, 20, 12, 0, 0) do
      category = create(:habit_category, user: user)
      habit = create(:user_habit,
        user: user,
        habit_category: category,
        name: "Agua",
        frequency_type: "daily",
        activation_date: Date.new(2026, 1, 1))
      create(:habit_completion, user_habit: habit, completed_on: Date.new(2026, 4, 18), status: "done")
      create(:habit_completion, user_habit: habit, completed_on: Date.new(2026, 4, 19), status: "done")

      get my_day_path, params: { fecha: "2026-04-19" }

      expect(response.body).to include(%(data-habit-streak="2"))
    end
  end
end
