# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Reports (Informes)", type: :request do
  let(:password) { "Password123!" }
  let(:user) { create(:user, password: password, timezone: "Etc/UTC") }

  describe "GET /informes" do
    # [REQ-RPT-001, REQ-RPT-002, REQ-RPT-003]
    it "redirects to sign in when not authenticated" do
      get informes_path

      expect(response).to redirect_to(sign_in_path)
    end

    # [REQ-RPT-001, REQ-RPT-002, REQ-RPT-003]
    it "renders the report sections for a signed-in user" do
      post sign_in_path, params: { email: user.email, password: password }

      travel_to Time.utc(2026, 4, 20, 12, 0, 0) do
        get informes_path

        expect(response).to have_http_status(:ok)
        expect(response.body).to include(I18n.t("reports.show.heading"))
        expect(response.body).to include("reports-fulfillment")
        expect(response.body).to include("reports-streaks")
        expect(response.body).to include("reports-weight")
      end
    end

    # [REQ-RPT-001]
    it "redirects with alert when fecha is invalid" do
      post sign_in_path, params: { email: user.email, password: password }

      get informes_path, params: { fecha: "not-a-date" }

      expect(response).to redirect_to(informes_path)
      expect(flash[:alert]).to eq(I18n.t("reports.flash.invalid_date"))
    end

    # [REQ-RPT-002]
    it "redirects with alert when fecha is in the future" do
      post sign_in_path, params: { email: user.email, password: password }

      travel_to Time.utc(2026, 4, 20, 12, 0, 0) do
        get informes_path, params: { fecha: "2026-04-21" }

        expect(response).to redirect_to(informes_path)
        expect(flash[:alert]).to eq(I18n.t("reports.flash.future_date"))
      end
    end

    # [REQ-RPT-001]
    it "lists fulfillment for a habit with due days in the reference week" do
      post sign_in_path, params: { email: user.email, password: password }
      category = create(:habit_category, user: user)
      habit = create(:user_habit,
        user: user,
        habit_category: category,
        frequency_type: "daily",
        activation_date: Date.new(2026, 4, 1))

      travel_to Time.utc(2026, 4, 20, 12, 0, 0) do
        get informes_path, params: { fecha: "2026-04-15" }

        expect(response).to have_http_status(:ok)
        expect(response.body).to include(habit.name)
        expect(response.body).to include(category.name)
      end
    end
  end
end
