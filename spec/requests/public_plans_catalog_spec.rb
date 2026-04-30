# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Public plans catalog", type: :request do
  let(:viewer) { create(:user, password: "Password123!", timezone: "Etc/UTC") }
  let(:author) { create(:user, password: "Password123!", timezone: "Etc/UTC") }

  # [REQ-CAT-001] — plans public catalog (REQ-ID finalized in SPEC step S11 of task plan)
  it "requires authentication" do
    get public_plans_path

    expect(response).to redirect_to(sign_in_path)
  end

  # [REQ-CAT-001] — plans public catalog (REQ-ID finalized in SPEC step S11 of task plan)
  it "responds ok for authenticated index and show" do
    public_plan = Plan.create!(user: author, name: "Catálogo", publicly_shareable: true)

    post sign_in_path, params: { email: viewer.email, password: "Password123!" }

    get public_plans_path
    expect(response).to have_http_status(:ok)

    get public_plan_path(public_plan)
    expect(response).to have_http_status(:ok)
  end
end
