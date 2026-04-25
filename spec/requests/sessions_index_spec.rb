# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Sessions index", type: :request do
  let(:password) { "Password123!" }
  let(:user) { create(:user, password: password, timezone: "Etc/UTC") }

  # [REQ-I18N-001]
  it "does not render raw user agent or exact IP on /sessions" do
    post sign_in_path, params: { email: user.email, password: password }

    raw_user_agent = "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 Chrome/123.0.0.0 Safari/537.36"
    raw_ip = "::1"
    user.sessions.create!(user_agent: raw_user_agent, ip_address: raw_ip)

    get sessions_path

    expect(response).to have_http_status(:ok)
    expect(response.body).not_to include(raw_user_agent)
    expect(response.body).not_to include(raw_ip)
  end
end

