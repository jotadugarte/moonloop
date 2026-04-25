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

    # [REQ-RPT-001, REQ-RPT-002, REQ-RPT-003]
    it "updates copy and can render a single section when requested" do
      post sign_in_path, params: { email: user.email, password: password }

      travel_to Time.utc(2026, 4, 20, 12, 0, 0) do
        get informes_path

        expect(response).to have_http_status(:ok)
        formatted = I18n.l(Date.new(2026, 4, 20), format: :long, locale: I18n.default_locale)
        expect(response.body).not_to include(I18n.t("reports.show.reference_period_intro", date: formatted, locale: I18n.default_locale))
        expect(response.body).to include(%(#{I18n.t("reports.show.date_label")}))

        get informes_path, params: { section: "streaks" }
        expect(response).to have_http_status(:ok)
        expect(response.body).to include("reports-streaks")
        expect(response.body).not_to include("reports-fulfillment")
        expect(response.body).not_to include("reports-weight")
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
        expect(response.body).to match(%r{\b0/7\b})
      end
    end

    # [REQ-RPT-002]
    it "does not list an inactive habit in streaks when it has no completions in the reference window" do
      post sign_in_path, params: { email: user.email, password: password }
      category = create(:habit_category, user: user)
      habit = create(:user_habit,
        user: user,
        habit_category: category,
        frequency_type: "daily",
        activation_date: Date.new(2026, 3, 1),
        active: true)

      travel_to Time.utc(2026, 4, 20, 12, 0, 0) do
        create(:habit_completion, user_habit: habit, completed_on: Date.new(2026, 3, 5), status: "done")
        habit.update!(active: false)

        get informes_path, params: { fecha: "2026-04-15" }

        expect(response).to have_http_status(:ok)
        streaks = response.body.split('data-test="reports-streaks"').last.split("</section>").first
        expect(streaks).not_to include(habit.name)
      end
    end

    # [REQ-RPT-003, REQ-WGT-004]
    it "charts weight axis and tooltips in pounds for imperial users" do
      imperial = create(:user, password: password, timezone: "Etc/UTC", height_cm: 180, body_unit_system: "imperial_us")
      post sign_in_path, params: { email: imperial.email, password: password }

      travel_to Time.utc(2026, 4, 20, 12, 0, 0) do
        create(:weight_log, user: imperial, weight_kg: 70.0, height_cm: 180, logged_at: Time.utc(2026, 4, 10, 10, 0, 0))
        create(:weight_log, user: imperial, weight_kg: 80.0, height_cm: 180, logged_at: Time.utc(2026, 4, 18, 10, 0, 0))

        get informes_path

        expect(response).to have_http_status(:ok)
        expect(response.body).to include("154.3")
        expect(response.body).to include("176.4")
        expect(response.body).to include(I18n.t("reports.show.weight_chart_legend", unit: I18n.t("body_metrics.unit_lb")))
      end
    end

    # [REQ-RPT-003, REQ-WGT-004]
    it "charts weight axis in kilograms for metric users" do
      post sign_in_path, params: { email: user.email, password: password }

      travel_to Time.utc(2026, 4, 20, 12, 0, 0) do
        create(:weight_log, user: user, weight_kg: 70.5, height_cm: 175, logged_at: Time.utc(2026, 4, 10, 10, 0, 0))

        get informes_path

        expect(response.body).to include("70.5")
        expect(response.body).to include(I18n.t("reports.show.weight_chart_legend", unit: I18n.t("body_metrics.unit_kg")))
      end
    end
  end
end
