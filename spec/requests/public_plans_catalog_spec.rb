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
  it "does not expose author email in index or show HTML" do
    post sign_in_path, params: { email: viewer.email, password: "Password123!" }

    plan = Plan.create!(user: author, name: "Shared plan", publicly_shareable: true)
    expect(author.email).to be_present

    get public_plans_path
    expect(response.body).not_to include(author.email)

    get public_plan_path(plan)
    expect(response.body).not_to include(author.email)
  end
end

