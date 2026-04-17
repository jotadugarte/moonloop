# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Phases dashboard", type: :request do
  let(:user) { create(:user, password: "Password123!", timezone: "Etc/UTC") }

  before do
    post sign_in_path, params: { email: user.email, password: "Password123!" }
  end

  # [REQ-MENU-003]
  it "shows the phase plan with current week when anchor is set" do
    user.update!(phase_one_starts_on: Date.new(2026, 4, 10))
    travel_to(Date.new(2026, 4, 12)) do
      get phase_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include(I18n.t("phases.show.current_week", index: 1))
    end
  end

  # [REQ-MENU-003]
  it "updates the phase 1 start date" do
    patch phase_path, params: { user: { phase_one_starts_on: "2026-05-01" } }

    expect(response).to have_http_status(:found)
    expect(user.reload.phase_one_starts_on).to eq(Date.new(2026, 5, 1))
  end
end
