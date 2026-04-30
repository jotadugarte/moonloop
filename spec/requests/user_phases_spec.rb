# frozen_string_literal: true

require "rails_helper"

RSpec.describe "User phases", type: :request do
  let(:user) { create(:user, password: "Password123!") }

  before do
    post sign_in_path, params: { email: user.email, password: "Password123!" }
  end

  it "lists phases and creates a phase" do
    get user_phases_path
    expect(response).to have_http_status(:ok)
    expect(response.body).to include(I18n.t("user_phases.index.heading"))

    post user_phases_path, params: { phase: { name: "Base", weeks_total: 3, publicly_shareable: "0" } }
    expect(response).to redirect_to(edit_user_phase_path(Phase.find_by!(name: "Base")))
    follow_redirect!
    expect(response.body).to include(I18n.t("user_phases.edit.heading", name: "Base"))
  end

  it "returns 422 when create is invalid" do
    post user_phases_path, params: { phase: { name: "", weeks_total: 1 } }
    expect(response).to have_http_status(:unprocessable_content)
  end
end
