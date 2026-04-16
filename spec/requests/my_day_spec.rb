# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Mi Día (My Day)", type: :request do
  let(:user) { create(:user, password: "Password123!", timezone: "Etc/UTC") }

  before do
    post sign_in_path, params: { email: user.email, password: "Password123!" }
  end

  # [REQ-DAY-001]
  it "renders the page for the signed-in user" do
    get my_day_path

    expect(response).to have_http_status(:ok)
    expect(response.body).to include(I18n.t("my_day.show.heading"))
  end

  # [REQ-DAY-001]
  it "lists active habits that are due on the user's local today" do
    travel_to Time.utc(2026, 4, 16, 12, 0, 0) do
      category = create(:habit_category, user: user, name: "Salud")
      create(:user_habit,
        user: user,
        habit_category: category,
        name: "Agua diaria",
        frequency_type: "daily",
        activation_date: Date.new(2026, 1, 1))

      get my_day_path

      expect(response.body).to include("Agua diaria")
      expect(response.body).to include("Salud")
    end
  end

  # [REQ-DAY-001]
  it "does not list inactive habits" do
    travel_to Time.utc(2026, 4, 16, 12, 0, 0) do
      category = create(:habit_category, user: user)
      create(:user_habit,
        user: user,
        habit_category: category,
        name: "Inactivo",
        frequency_type: "daily",
        activation_date: Date.new(2026, 1, 1),
        active: false)

      get my_day_path

      expect(response.body).not_to include("Inactivo")
    end
  end

  # [REQ-DAY-001]
  it "does not list habits that are not due on that local day" do
    travel_to Time.utc(2026, 4, 16, 12, 0, 0) do
      # 2026-04-16 is Thursday (wday 4); only Mon/Tue in schedule
      category = create(:habit_category, user: user)
      create(:user_habit,
        user: user,
        habit_category: category,
        name: "Solo Lun Mar",
        frequency_type: "weekdays",
        frequency_params: { "weekdays" => [ 1, 2 ] },
        activation_date: Date.new(2026, 1, 1))

      get my_day_path

      expect(response.body).not_to include("Solo Lun Mar")
    end
  end

  # [REQ-DAY-001]
  it "does not list habits before their activation_date window" do
    travel_to Time.utc(2026, 4, 16, 12, 0, 0) do
      category = create(:habit_category, user: user)
      create(:user_habit,
        user: user,
        habit_category: category,
        name: "Empieza después",
        frequency_type: "every_x_days",
        frequency_params: { "interval" => 1 },
        activation_date: Date.new(2026, 5, 1))

      get my_day_path

      expect(response.body).not_to include("Empieza después")
    end
  end
end
