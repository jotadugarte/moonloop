# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Public phases catalog", type: :request do
  let(:viewer) { create(:user, password: "Password123!", timezone: "Etc/UTC") }

  # [REQ-CAT-001] — phases public catalog (REQ-ID finalized in SPEC step S11 of task plan)
  it "requires authentication" do
    get public_phases_path

    expect(response).to redirect_to(sign_in_path)
  end

  # [REQ-CAT-001] — phases public catalog (REQ-ID finalized in SPEC step S11 of task plan)
  it "responds ok for authenticated index and show" do
    post sign_in_path, params: { email: viewer.email, password: "Password123!" }

    get public_phases_path
    expect(response).to have_http_status(:ok)

    get public_phase_path(123)
    expect(response).to have_http_status(:ok)
  end
end

