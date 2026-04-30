# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Phase adoption source sync", type: :request do
  let(:author) { create(:user, password: "Password123!", timezone: "Etc/UTC") }
  let(:adopter) { create(:user, password: "Password123!", timezone: "Etc/UTC") }

  # [REQ-CAT-001] — phases adoption sync apply (REQ-ID finalized in SPEC step S11 of task plan)
  it "applies source update for an adopted phase" do
    source = Phase.create!(user: author, name: "Plantilla", weeks_total: 4, publicly_shareable: true)

    post sign_in_path, params: { email: adopter.email, password: "Password123!" }
    post adopt_public_phase_path(source), params: { name: "Mi fase" }
    copy = Phase.find_by!(user: adopter, name: "Mi fase")

    source.update!(weeks_total: 6)
    fp = Phases::ContentFingerprint.for_phase(source.reload)

    post accept_source_update_phase_path(copy), params: { expected_origin_fingerprint: fp }

    expect(response).to have_http_status(:found)
    expect(copy.reload.weeks_total).to eq(6)
    expect(copy.source_sync_fingerprint).to eq(fp)
  end
end
