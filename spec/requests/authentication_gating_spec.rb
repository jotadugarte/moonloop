require "rails_helper"

RSpec.describe "Authentication gating", type: :request do
  # [REQ-AUTH-003]
  it "redirects to sign in when no valid session cookie is present" do
    get root_path

    expect(response).to redirect_to(sign_in_path)
  end
end
