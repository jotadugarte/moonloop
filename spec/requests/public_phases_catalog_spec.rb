# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Public phases catalog", type: :request do
  let(:viewer) { create(:user, password: "Password123!", timezone: "Etc/UTC") }
  let(:author) { create(:user, password: "Password123!", timezone: "Etc/UTC") }

  # [REQ-CAT-001] — phases public catalog (REQ-ID finalized in SPEC step S11 of task plan)
  it "requires authentication" do
    get public_phases_path

    expect(response).to redirect_to(sign_in_path)
  end

  # [REQ-CAT-001] — phases public catalog (REQ-ID finalized in SPEC step S11 of task plan)
  it "does not expose author email in index or show HTML" do
    post sign_in_path, params: { email: viewer.email, password: "Password123!" }

    phase = Phase.create!(user: author, name: "Shared phase", publicly_shareable: true, weeks_total: 4)
    expect(author.email).to be_present

    get public_phases_path
    expect(response.body).not_to include(author.email)

    get public_phase_path(phase)
    expect(response.body).not_to include(author.email)
  end
end

