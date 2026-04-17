# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Weight log navigation", type: :request do
  let(:user) { create(:user, password: "Password123!", timezone: "Etc/UTC") }

  before do
    post sign_in_path, params: { email: user.email, password: "Password123!" }
  end

  # [REQ-WGT-002]
  it "includes weight history and log-weight links on the home page" do
    get root_path

    expect(response).to have_http_status(:ok)
    expect(response.body).to include(weight_logs_path)
    expect(response.body).to include(new_weight_log_path)
    expect(response.body).to include(I18n.t("home.index.weight_history"))
    expect(response.body).to include(I18n.t("home.index.log_weight"))
  end

  # [REQ-WGT-002]
  it "includes weight history and log-weight links on profile edit" do
    get edit_profile_path

    expect(response).to have_http_status(:ok)
    expect(response.body).to include(weight_logs_path)
    expect(response.body).to include(new_weight_log_path)
  end
end
